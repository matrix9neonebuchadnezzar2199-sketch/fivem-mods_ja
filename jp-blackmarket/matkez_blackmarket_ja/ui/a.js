const cont = document.getElementById('blackcont');
const blackName = document.getElementById('blackname');
const blackItems = document.getElementById('blackitems');
const cartItems = document.getElementById('cartitems');
const total = document.getElementById('totalwrapper');
const search = document.getElementById('search');
const level = document.getElementById('leveln');
const xpTxt = document.getElementById('xp');
const progressFill = document.getElementById('filler');
const itemsWrapp = document.getElementById('itemswrapper');
const cartWrapp = document.getElementById('cartwrapper');
const levelWrapp = document.getElementById('levelwrap');
const orderBtn = document.getElementById('order');
const cartLabel = document.getElementById('cartlabel');
let items = [];
let cart = [];
let locales
let currencyItem
let currencyImg

function setItems(list, currency, currencyImage) {
    blackItems.innerHTML = '';
    currencyItem = currency
    currencyImg = currencyImage
    list.forEach((e, i) => {
        const div = document.createElement('div');
        div.className = 'item'
        if (!e.hasLevel) {
            div.style.opacity = '0.6';
            div.style.pointerEvents = 'none';
            div.style.cursor = 'not-allowed'
        }
        div.innerHTML = `
            <svg class="levellock" style="${e.hasLevel ? 'display:none' : 'display:flex; pointer-events:none'}" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><!--!Font Awesome Free v7.2.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2026 Fonticons, Inc.--><path d="M256 160L256 224L384 224L384 160C384 124.7 355.3 96 320 96C284.7 96 256 124.7 256 160zM192 224L192 160C192 89.3 249.3 32 320 32C390.7 32 448 89.3 448 160L448 224C483.3 224 512 252.7 512 288L512 512C512 547.3 483.3 576 448 576L192 576C156.7 576 128 547.3 128 512L128 288C128 252.7 156.7 224 192 224z"/></svg>
            <img src="${e.image}">
            <div class="iteminfo">
                <span class="itemname">${e.label}</span>
                <div class="itempricewrapper"> 
                    <span class="itemprice">${e.price}${currencyItem === 'money' ? '$' : ''} </span>
                    <img src="${currencyImg}" style="${currencyItem === 'money' ? 'display:none' : ''}">
                </div>
            </div>
            <span class="tip">${locales.addTip || 'Left click to add to cart'}</span>
        `
        div.onclick = () => addToCart(i)
        div.onmouseenter = () => playSound('hover.mp3', 0.5)
        blackItems.append(div)
    });
}

function refreshCart() {
    cartItems.innerHTML = ''
    let totalPrice = 0
    cart.forEach((e, i) => {
        const div = document.createElement('div');
        div.className = 'item'

        div.innerHTML = `
            <img src="${e.image}">
            <div class="iteminfo">
                <span class="itemname">${e.label}</span>
                <div class="itempricewrapper"> 
                    <span class="itemprice">${e.price}${currencyItem === 'money' ? '$' : ''} </span>
                    <img src="${currencyImg}" style="${currencyItem === 'money' ? 'display:none' : ''}">
                </div>
            </div>
            <input type="number" min="1" value="${e.amount}" onchange="changeAmount(${i}, this.value)">
            <span class="tip">${locales.removeTip || 'Right click to remove from cart'}</span>
        `
        div.addEventListener('mousedown', function(ev) {
            if (ev.button === 2) {
                cart.splice(i, 1)
                refreshCart();
                playSound('remove.mp3', 0.5);
            }
        })
        div.onmouseenter = () => playSound('hover.mp3', 0.5)
        cartItems.append(div)
        totalPrice = totalPrice + e.price * e.amount
    })
    setTotalPrice(totalPrice);
}

function setTotalPrice(price) {
    total.innerHTML = `
    <div id="totalwrapper">
        <span id="total">${price}</span>
        <span id="totalcurrency" style="${currencyItem === 'money' ? 'display: static' : 'display: none'}">$</span>
        <img id="totalimg" src="${currencyImg}" style="${currencyItem !== 'money' ? 'display: static' : 'display: none'}">
    </div>
    `
}

function addToCart(i) {
    const item = items[i]
    const inCart = cart.find(v => v.item == item.name);
    if (inCart) {
        inCart.amount++
    } else {
        cart.push({item: item.name, price: item.price, image: item.image, label: item.label, amount: 1})
    }
    refreshCart();
    playSound('add.mp3', 0.5);
}

function changeAmount(indx, val) {
    let amount = Number(val);
    if (amount < 1) amount = 1;
    cart[indx].amount = amount;
    refreshCart();
}

async function order() {
    if (cart.length < 1) return;
    try {
        const resp = await fetch(`https://${GetParentResourceName()}/order`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify({
                items: cart
            })
        });
        
        const res = await resp.json();
        if (res === true) {
            showUi(false)
        };
    } catch (e) {
        console.log(e)
    }
}

function showUi(t) {
    if (t) {
        cont.style.display = 'flex';
        animate(true);
        refreshCart();
        setTotalPrice(0);
    } else {
        animate(false)
        fetch(`https://${GetParentResourceName()}/close`);
        cart = [];
        items = [];
        cont.style.display = 'none'
    }
}

function animate(r) {
    if (r) {
        itemsWrapp.classList.add('slideitems');
        cartWrapp.classList.add('slidecart');
        levelWrapp.classList.add('slidelevel');
    } else {
        itemsWrapp.classList.remove('slideitems');
        cartWrapp.classList.remove('slidecart');
        levelWrapp.classList.remove('slidelevel');
    }
}

function setLevel(lvl, xp, nextXp, useLevels) {
    if (!useLevels) {
        levelWrapp.style.display = 'none';
        return;
    }
    levelWrapp.style.display = 'flex';
    const progress = (xp / nextXp) * 100;
    const clamped = Math.max(0, Math.min(100, progress));
    level.innerText = lvl;
    xpTxt.innerText = `${xp}/${nextXp} XP`
    progressFill.style.width = clamped + '%'
}

function playSound(file, volume) {
    const sound = new Audio(`sounds/${file}`);
    sound.volume = volume;
    sound.play();
    sound.onended = () => {
        sound.pause();
        sound.currentTime = 0;
    };
}

search.addEventListener('input', () => {
    const val = search.value.toLowerCase().trim();
    const filt = items.filter(v => v.label.toLowerCase().includes(val) || v.name.toLowerCase().includes(val));
    setItems(filt, currencyItem, currencyImg)
})

window.addEventListener('message', (e) => {
    const d = e.data
    if (d.event === 'show') {
        items = d.items
        setItems(d.items, d.currencyItem, d.currencyImg);
        setLevel(d.level, d.xp, d.nextXp, d.useLevels);
        showUi(true);
        blackName.innerText = d.label
    } else if (d.event === 'locales') {
        locales = d.locales
    };
})

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        showUi(false)
    }
})

window.onload = function() {
    setTimeout(() => {
        if (!locales) return;
        if (locales.order)  orderBtn.innerText = locales.order;
        if (locales.search) search.placeholder = locales.search;
        if (locales.cart)   cartLabel.innerText = locales.cart;
        if (locales.level) {
            const ll = document.getElementById('levellabel');
            if (ll) ll.innerText = locales.level;
        }
    }, 2000);
}