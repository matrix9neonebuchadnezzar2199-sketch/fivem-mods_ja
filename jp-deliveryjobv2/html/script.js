// 配達ジョブ UI制御スクリプト（日本語版）
window.addEventListener('message', function (event) {
    const data = event.data;

    // ルート開始時：配達リストを生成
    if (data.action === 'START_ROUTE') {
        const titleEl = document.getElementById('route-header-title');
        if (titleEl) {
            const name = data.routeName || '';
            titleEl.textContent = name ? `配達ルート: ${name}` : '配達ルート';
        }

        const list = document.getElementById('delivery-list');
        list.innerHTML = ''; // 前回のリストをクリア

        for (let i = 1; i <= data.amount; i++) {
            const li = document.createElement('li');
            li.id = `stop-${i}`;
            li.innerHTML = `
                <span class="stop-info">配達 #${i}</span>
                <i class="fas fa-times status-icon pending" id="icon-${i}"></i>
            `;
            list.appendChild(li);
        }

        document.getElementById('container').style.display = 'block';
    }
    // 配達完了時：チェックマークを付ける
    else if (data.action === 'UPDATE_STOP') {
        const index = data.index;
        const li = document.getElementById(`stop-${index}`);
        const icon = document.getElementById(`icon-${index}`);

        if (li && icon) {
            li.classList.add('completed');
            icon.classList.remove('fa-times', 'pending');
            icon.classList.add('fa-check', 'completed');
        }
    }
    // 全配達後：本部帰還ステップを追加
    else if (data.action === 'ADD_RETURN_STOP') {
        const list = document.getElementById('delivery-list');
        const li = document.createElement('li');
        li.id = 'stop-return';
        li.innerHTML = `
            <span class="stop-info">本部に帰還</span>
            <i class="fas fa-times status-icon pending" id="icon-return"></i>
        `;
        list.appendChild(li);
    }
    // UI閉鎖
    else if (data.action === 'CLOSE_UI') {
        const titleEl = document.getElementById('route-header-title');
        if (titleEl) {
            titleEl.textContent = '配達ルート';
        }
        document.getElementById('container').style.display = 'none';
        document.getElementById('delivery-list').innerHTML = '';
    }
});
