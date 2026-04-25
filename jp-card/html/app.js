const container = document.getElementById("card-container");
const card = document.getElementById("card");
const cardFront = card.querySelector(".card-front");
const cardRank = card.querySelector(".card-rank");
const cardSuitLarge = card.querySelector(".card-suit-large");
const topLeft = card.querySelector(".top-left");
const bottomRight = card.querySelector(".bottom-right");
const jokerLabel = card.querySelector(".joker-label");

let flipTimer = null;
let hideTimer = null;

function clearTimers() {
  if (flipTimer) {
    window.clearTimeout(flipTimer);
    flipTimer = null;
  }
  if (hideTimer) {
    window.clearTimeout(hideTimer);
    hideTimer = null;
  }
}

function setCardColor(color) {
  cardFront.classList.remove("red", "black");
  cardFront.classList.add(color === "red" ? "red" : "black");
}

function setJokerMode(isJoker) {
  cardFront.classList.toggle("joker", Boolean(isJoker));
  jokerLabel.style.display = isJoker ? "block" : "none";
}

function updateCard(data) {
  const isJoker = Boolean(data.isJoker);
  setJokerMode(isJoker);
  setCardColor(data.color);

  if (isJoker) {
    cardRank.textContent = "JOKER";
    cardSuitLarge.textContent = data.suit || "🃏";
    topLeft.querySelector(".corner-rank").textContent = "J";
    topLeft.querySelector(".corner-suit").textContent = data.suit || "🃏";
    bottomRight.querySelector(".corner-rank").textContent = "J";
    bottomRight.querySelector(".corner-suit").textContent = data.suit || "🃏";
    jokerLabel.textContent = data.jokerName || "JOKER";
  } else {
    const rankText = data.display || data.rank || "";
    const suitText = data.suit || "";
    cardRank.textContent = rankText;
    cardSuitLarge.textContent = suitText;
    topLeft.querySelector(".corner-rank").textContent = rankText;
    topLeft.querySelector(".corner-suit").textContent = suitText;
    bottomRight.querySelector(".corner-rank").textContent = rankText;
    bottomRight.querySelector(".corner-suit").textContent = suitText;
    jokerLabel.textContent = "";
  }
}

function showCard(data) {
  clearTimers();
  updateCard(data);

  card.classList.remove("flipped", "shake");
  container.classList.remove("fade-out");
  container.classList.add("visible");

  requestAnimationFrame(() => {
    container.classList.add("fade-in");
  });

  flipTimer = window.setTimeout(() => {
    card.classList.add("flipped");
    if (data.isJoker) {
      window.setTimeout(() => {
        card.classList.add("shake");
      }, 650);
    }
  }, 300);
}

function hideCard() {
  clearTimers();
  container.classList.remove("fade-in");
  container.classList.add("fade-out");
  hideTimer = window.setTimeout(() => {
    card.classList.remove("flipped", "shake");
    container.classList.remove("visible", "fade-out");
    container.style.display = "";
  }, 300);
}

window.addEventListener("message", (event) => {
  const data = event.data || {};
  switch (data.type) {
    case "showCard":
      showCard(data);
      break;
    case "hideCard":
      hideCard();
      break;
    default:
      break;
  }
});
