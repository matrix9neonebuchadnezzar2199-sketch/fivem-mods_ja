const container = document.getElementById("coin-container");
const coin = document.getElementById("coin");
const resultText = document.getElementById("result-text");

let hideTimer = null;

function clearHideTimer() {
  if (hideTimer) {
    window.clearTimeout(hideTimer);
    hideTimer = null;
  }
}

function resetState() {
  coin.classList.remove("tossing");
  resultText.classList.remove("show");
  resultText.textContent = "";
}

function showToss(data) {
  clearHideTimer();
  resetState();

  const finalRotation = data.side === "tails" ? "2340deg" : "2160deg";
  const durationMs = Number(data.animationTime) > 0 ? Number(data.animationTime) : 2000;
  coin.style.setProperty("--final-rotation", finalRotation);
  coin.style.setProperty("--animation-duration", `${durationMs}ms`);

  container.classList.remove("hiding");
  container.classList.add("visible");

  requestAnimationFrame(() => {
    coin.classList.add("tossing");
  });

  const onEnd = () => {
    coin.removeEventListener("animationend", onEnd);
    resultText.textContent = data.label || "";
    resultText.classList.add("show");
  };
  coin.addEventListener("animationend", onEnd);
}

function hide() {
  clearHideTimer();
  container.classList.remove("visible");
  container.classList.add("hiding");
  hideTimer = window.setTimeout(() => {
    container.classList.remove("hiding");
    container.style.display = "";
    resetState();
  }, 400);
}

window.addEventListener("message", (event) => {
  const data = event.data || {};
  switch (data.type) {
    case "toss":
      showToss(data);
      break;
    case "hide":
      hide();
      break;
    default:
      break;
  }
});
