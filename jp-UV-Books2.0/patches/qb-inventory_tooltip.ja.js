// qb-inventory/html/js/app.js のアイテム情報表示部分の book ブロックを
// 以下に置き換え（または追加）してください。

if (itemData.name == "book" && itemData.info && itemData.info.title) {
    const info   = itemData.info || {};
    const title  = info.title  || label || '本';
    const author = info.author || '不明';
    const genre  = info.genre  || '';

    $(".item-info-title").html(`<p>${title}</p>`);

    const rows = [
        `<p><strong>タイトル：</strong><span>${title}</span></p>`,
        `<p><strong>著者：</strong><span>${author}</span></p>`,
    ];
    if (genre) {
        rows.push(`<p><strong>ジャンル：</strong><span>${genre}</span></p>`);
    }
    $(".item-info-description").html(rows.join(''));
}