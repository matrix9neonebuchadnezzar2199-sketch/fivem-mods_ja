const SizeStyle = Quill.import('attributors/style/size');
/** ツールバー・i18n（applyQuillSizeLabels）と一致 */
SizeStyle.whitelist = [false, '14px', '24px', '32px'];
Quill.register(SizeStyle, true);

const ColorStyle = Quill.import('attributors/style/color');
Quill.register(ColorStyle, true);

const AlignStyle = Quill.import('attributors/style/align');
Quill.register(AlignStyle, true);

/** ui/fonts と対応（Quill の class 名は英小文字・ハイフン） */
const B2B_FONT_WHITELIST = [
    'noto-sans-jp',
    'noto-serif-jp',
    'shippori-mincho',
    'klee-one',
    'yuji-mai',
    'zen-kurenaido',
    false
];

let FontFormat = null;
try {
    FontFormat = Quill.import('formats/font');
} catch (e) {
    FontFormat = null;
}
let b2bFontToolbarRow = null;
if (FontFormat) {
    FontFormat.whitelist = B2B_FONT_WHITELIST;
    Quill.register(FontFormat, true);
    b2bFontToolbarRow = [{ 'font': B2B_FONT_WHITELIST }];
} else {
    console.warn('[jp-b2b_documents] Quill に formats/font がありません — フォントピッカーを省略します');
}

const toolbarRows = [
    [{ 'header': [1, 2, 3, false] }],
];
if (b2bFontToolbarRow) {
    toolbarRows.push(b2bFontToolbarRow);
}
toolbarRows.push(
    [{ size: [false, '14px', '24px', '32px'] }],
    ['bold', 'italic', 'underline', 'strike'],
    [{ 'color': [] }, { 'background': [] }],
    [{ 'align': [] }],
    ['image', 'clean']
);

const quill = new Quill('#editor', {
    theme: 'snow',
    modules: {
        toolbar: toolbarRows
    }
});

/** FiveM NUI では prompt が効かない／blob URL は保存不能のため、ファイル→data URL で挿入 */
const B2B_IMAGE_MAX_BYTES = 1800000;
function b2bRegisterImageToolbarHandler() {
    const toolbar = quill.getModule('toolbar');
    if (!toolbar) return;
    const handler = function () {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        input.style.display = 'none';
        document.body.appendChild(input);
        input.onchange = function () {
            const file = input.files && input.files[0];
            if (file) {
                if (file.size > B2B_IMAGE_MAX_BYTES) {
                    console.warn('[jp-b2b_documents] 画像が大きすぎます（約 ' + Math.round(B2B_IMAGE_MAX_BYTES / 1000000) + 'MB 以下）');
                } else {
                    const reader = new FileReader();
                    reader.onload = function (ev) {
                        const url = ev.target && ev.target.result;
                        if (!url) return;
                        const range = quill.getSelection(true) || { index: Math.max(0, quill.getLength() - 1), length: 0 };
                        quill.insertEmbed(range.index, 'image', url, 'user');
                        quill.setSelection(range.index + 1, 0, 'user');
                    };
                    reader.readAsDataURL(file);
                }
            }
            if (input.parentNode) input.parentNode.removeChild(input);
        };
        input.click();
    };
    if (typeof toolbar.addHandler === 'function') {
        toolbar.addHandler('image', handler);
    } else if (toolbar.handlers) {
        toolbar.handlers.image = handler;
    }
}
b2bRegisterImageToolbarHandler();

/**
 * Quill 2 は Enter でインライン書式を引き継がない（PR #3428）。
 * keyboard.addBinding で return false しても「先に動いたバインディング」で処理が止まり当ハンドラが呼ばれないため、
 * capture 段階の keydown で書式を覚え、text-change で改行を検出したら再適用する。
 */
/**
 * 改行後の再適用。header は含めない（見出しはブロック単位の意味なので Normal へ戻るのは許容。
 * header を先に付けると font が消えることがあるため、インライン→align の順。
 */
const B2B_REAPPLY_AFTER_ENTER_ORDER = [
    'font', 'bold', 'italic', 'underline', 'strike', 'color', 'background', 'size', 'align'
];
let b2bEnterPreserveFormats = null;

quill.root.addEventListener('keydown', function (e) {
    if (e.isComposing) return;
    if (e.key === 'Enter') {
        const range = quill.getSelection();
        b2bEnterPreserveFormats = range ? quill.getFormat(range) : null;
    } else {
        b2bEnterPreserveFormats = null;
    }
}, true);

function b2bDeltaLooksLikeEnterOnly(delta) {
    const ops = delta.ops || [];
    for (let i = 0; i < ops.length; i++) {
        const ins = ops[i].insert;
        if (typeof ins === 'string' && ins.length > 0 && ins !== '\n') {
            return false;
        }
    }
    return ops.some(function (op) {
        return op.insert === '\n';
    });
}

quill.on('text-change', function (delta, _old, source) {
    if (source !== 'user' || !b2bEnterPreserveFormats) return;
    if (!b2bDeltaLooksLikeEnterOnly(delta)) return;
    const fmt = b2bEnterPreserveFormats;
    b2bEnterPreserveFormats = null;
    queueMicrotask(function () {
        const sel = quill.getSelection(true);
        if (!sel) return;
        B2B_REAPPLY_AFTER_ENTER_ORDER.forEach(function (key) {
            const v = fmt[key];
            if (v === undefined || v === false) return;
            quill.format(key, v, 'user');
        });
        const tb = quill.getModule('toolbar');
        if (tb && typeof tb.update === 'function') tb.update(sel);
    });
});

/** v2: 保存は Delta JSON（font 等が HTML 経路で落ちない）。旧データは HTML のまま。 */
const B2B_DELTA_PREFIX = '__B2B_DOC_QV1__\n';
/** Delta 化に失敗したときや ops が空のときのフォールバック（ロック事故防止） */
const B2B_HTML_PREFIX = '__B2B_DOC_HTML_V1__\n';

function b2bStripBom(s) {
    return s != null ? String(s).replace(/^\uFEFF/, '') : '';
}

function b2bEditorHasMeaningfulContent() {
    const root = quill && quill.root;
    if (!root) return false;
    const t = (root.innerText || '').replace(/\u00a0/g, ' ').trim();
    if (t.length > 0) return true;
    return !!root.querySelector('img');
}

function b2bCollectOpsFromEditor() {
    const d = quill.getContents();
    if (!d) return [];
    if (typeof d.toJSON === 'function') {
        try {
            const j = d.toJSON();
            if (j && Array.isArray(j.ops)) return j.ops;
        } catch (e) {
            console.warn('[jp-b2b_documents] Delta.toJSON 失敗', e);
        }
    }
    return Array.isArray(d.ops) ? d.ops : [];
}

/** DB からの HTML を Quill の Delta 経由で取り込む（レガシー HTML 用） */
function b2bLoadEditorHtml(html) {
    const raw = html != null ? String(html) : '';
    const trimmed = raw.trim();
    if (!trimmed) {
        quill.setContents([], 'silent');
        return;
    }
    try {
        const delta = quill.clipboard.convert({ html: trimmed });
        quill.setContents(delta, 'silent');
    } catch (e) {
        console.warn('[jp-b2b_documents] clipboard.convert に失敗、innerHTML で表示します', e);
        quill.root.innerHTML = trimmed;
    }
    if (quill.history && typeof quill.history.clear === 'function') {
        quill.history.clear();
    }
}

function b2bLoadDocumentContent(raw) {
    const str = b2bStripBom(raw);
    if (!str.trim()) {
        quill.setContents([], 'silent');
        if (quill.history && typeof quill.history.clear === 'function') quill.history.clear();
        return;
    }
    if (str.startsWith(B2B_HTML_PREFIX)) {
        b2bLoadEditorHtml(str.slice(B2B_HTML_PREFIX.length));
        return;
    }
    if (str.startsWith(B2B_DELTA_PREFIX)) {
        const json = str.slice(B2B_DELTA_PREFIX.length);
        try {
            const parsed = JSON.parse(json);
            const Delta = Quill.import('delta');
            const ops = Array.isArray(parsed && parsed.ops)
                ? parsed.ops
                : (Array.isArray(parsed) ? parsed : null);
            if (!ops) {
                throw new Error('Delta に ops がありません');
            }
            quill.setContents(new Delta(ops), 'silent');
        } catch (e) {
            console.warn('[jp-b2b_documents] Delta の parse に失敗 — 全体を clipboard 経由で読み込みます（復旧用）', e);
            b2bLoadEditorHtml(str);
        }
        if (quill.history && typeof quill.history.clear === 'function') {
            quill.history.clear();
        }
        return;
    }
    b2bLoadEditorHtml(str);
}

/**
 * 原則 Delta JSON。本文があるのに ops が空・stringify 失敗時は innerHTML プレフィックスで保存（消え事故防止）。
 */
/** NUI / MySQL の都合で巨大 JSON が切れたり失敗するため、超長は HTML 保存（base64 画像は長くなりがち） */
const B2B_DELTA_JSON_MAX = 900000;

function b2bSerializeDocForSave() {
    let ops = [];
    try {
        ops = b2bCollectOpsFromEditor();
    } catch (e) {
        console.warn('[jp-b2b_documents] getContents 失敗', e);
    }
    const hasMeaning = b2bEditorHasMeaningfulContent();
    const opsEmpty = !ops || ops.length === 0;
    try {
        if (hasMeaning && opsEmpty) {
            console.warn('[jp-b2b_documents] 本文があるのに Delta ops が空 — innerHTML で保存します');
            return B2B_HTML_PREFIX + quill.root.innerHTML;
        }
        const json = JSON.stringify({ ops: ops || [] });
        if (json.length > B2B_DELTA_JSON_MAX) {
            console.warn('[jp-b2b_documents] Delta が長すぎるため HTML で保存します');
            return B2B_HTML_PREFIX + quill.root.innerHTML;
        }
        return B2B_DELTA_PREFIX + json;
    } catch (e) {
        console.warn('[jp-b2b_documents] Delta の stringify 失敗 — innerHTML で保存します', e);
        return B2B_HTML_PREFIX + quill.root.innerHTML;
    }
}

quill.clipboard.addMatcher(Node.ELEMENT_NODE, (node, delta) => {
    delta.ops.forEach(op => {
        if (op.attributes) {
            if (op.attributes.size && op.attributes.size.includes('pt')) {
                let ptSize = parseFloat(op.attributes.size);
                op.attributes.size = Math.round(ptSize * 1.33) + "px";
            }
            if (['H1', 'H2', 'H3'].includes(node.tagName)) {
                op.attributes.bold = true;
            }
        }
    });
    return delta;
});

function applyQuillSizeLabels(loc) {
    if (!loc || !loc.ui_size_normal) return;
    const id = 'b2b-quill-size-i18n';
    let el = document.getElementById(id);
    if (!el) {
        el = document.createElement('style');
        el.id = id;
        document.head.appendChild(el);
    }
    const q = (s) => JSON.stringify(String(s));
    el.textContent = `
.ql-snow .ql-picker.ql-size .ql-picker-label::before,
.ql-snow .ql-picker.ql-size .ql-picker-item::before { content: ${q(loc.ui_size_normal)} !important; }
.ql-snow .ql-picker.ql-size .ql-picker-label[data-value="14px"]::before,
.ql-snow .ql-picker.ql-size .ql-picker-item[data-value="14px"]::before { content: ${q(loc.ui_size_small)} !important; }
.ql-snow .ql-picker.ql-size .ql-picker-label[data-value="24px"]::before,
.ql-snow .ql-picker.ql-size .ql-picker-item[data-value="24px"]::before { content: ${q(loc.ui_size_large)} !important; }
.ql-snow .ql-picker.ql-size .ql-picker-label[data-value="32px"]::before,
.ql-snow .ql-picker.ql-size .ql-picker-item[data-value="32px"]::before { content: ${q(loc.ui_size_title)} !important; }
`;
}

function applyQuillFontLabels(loc) {
    if (!loc || !loc.ui_font_default || !b2bFontToolbarRow) return;
    const id = 'b2b-quill-font-i18n';
    let el = document.getElementById(id);
    if (!el) {
        el = document.createElement('style');
        el.id = id;
        document.head.appendChild(el);
    }
    const q = (s) => JSON.stringify(String(s));
    const pairs = [
        ['false', loc.ui_font_default],
        ['noto-sans-jp', loc.ui_font_noto_sans],
        ['noto-serif-jp', loc.ui_font_noto_serif],
        ['shippori-mincho', loc.ui_font_shippori],
        ['klee-one', loc.ui_font_klee],
        ['yuji-mai', loc.ui_font_yuji_mai],
        ['zen-kurenaido', loc.ui_font_zen]
    ];
    const rules = pairs.map(([val, label]) => {
        const sel = val === 'false'
            ? `.ql-snow .ql-picker.ql-font .ql-picker-label:not([data-value])::before, .ql-snow .ql-picker.ql-font .ql-picker-item:not([data-value])::before, .ql-snow .ql-picker.ql-font .ql-picker-label[data-value="false"]::before, .ql-snow .ql-picker.ql-font .ql-picker-item[data-value="false"]::before`
            : `.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="${val}"]::before, .ql-snow .ql-picker.ql-font .ql-picker-item[data-value="${val}"]::before`;
        return `${sel} { content: ${q(label)} !important; }`;
    }).join('\n');
    el.textContent = rules;
}

window.addEventListener('message', (event) => {
    if (event.data.action !== "open") return;

    document.body.classList.remove('hidden');

    const loc = event.data.locale || {};
    document.documentElement.lang = event.data.lang || 'ja';

    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (loc[key]) el.textContent = loc[key];
    });
    document.querySelectorAll('[data-i18n-title]').forEach(el => {
        const key = el.getAttribute('data-i18n-title');
        if (loc[key]) el.title = loc[key];
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        if (loc[key]) el.placeholder = loc[key];
    });

    applyQuillSizeLabels(loc);
    applyQuillFontLabels(loc);

    window.b2bItemName = event.data.itemName || null;

    const title = event.data.title || loc.ui_untitled || "Untitled document";
    const content = event.data.content || "";
    const isLocked = (event.data.locked === true || event.data.locked === 1);

    document.getElementById('docTitle').value = title;
    b2bLoadDocumentContent(content);

    if (isLocked) {
        quill.enable(false);
        document.getElementById('docTitle').disabled = true;
        document.querySelector('.ql-toolbar').style.display = 'none';
        document.querySelectorAll('.btn-action').forEach(b => {
            if (!b.innerHTML.includes('fa-times')) b.style.display = 'none';
        });
    } else {
        quill.enable(true);
        document.getElementById('docTitle').disabled = false;
        document.querySelector('.ql-toolbar').style.display = 'block';
        document.querySelectorAll('.btn-action').forEach(b => b.style.display = 'flex');
    }
});

function closeUI() {
    document.body.classList.add('hidden');
    quill.setText('');
    quill.history.clear();
    window.b2bItemName = null;
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function triggerAction(actionType) {
    const contentPayload = b2bSerializeDocForSave();
    const titleInput = document.getElementById('docTitle');
    const docTitle = titleInput.value
        || titleInput.placeholder
        || "Untitled";

    if (actionType === 'duplicate') {
        const modal = document.getElementById('duplicateModal');
        if (modal) modal.classList.add('hidden');
    }

    fetch(`https://${GetParentResourceName()}/doAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            action: actionType,
            content: contentPayload,
            title: docTitle,
            itemName: window.b2bItemName
        })
    })
        .then(resp => resp.json())
        .then(success => {
            if (success) closeUI();
        });
}

function openModal(id) { document.getElementById(id).classList.remove('hidden'); }

function confirmLock() {
    const m = document.getElementById('lockModal');
    if (m) m.classList.add('hidden');
    triggerAction('lock');
}

document.onkeyup = (e) => {
    if (e.key !== "Escape") return;
    const lock = document.getElementById('lockModal');
    const dup = document.getElementById('duplicateModal');
    if (lock && !lock.classList.contains('hidden')) {
        lock.classList.add('hidden');
        return;
    }
    if (dup && !dup.classList.contains('hidden')) {
        dup.classList.add('hidden');
        return;
    }
    closeUI();
};
