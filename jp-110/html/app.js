const container = document.getElementById("radio-container");
const notification = document.getElementById("radio-notification");
const titleEl = document.querySelector(".radio-title");
const bodyEl = document.querySelector(".radio-body");

let hideTimer = null;

function resetTyping(text) {
  bodyEl.classList.remove("typing", "done");
  bodyEl.textContent = text;
  const steps = Math.max(text.length, 4);
  bodyEl.style.setProperty("--typing-steps", String(steps));
  bodyEl.style.setProperty("--typing-duration", `${Math.min(Math.max(steps * 0.05, 0.4), 1.8)}s`);
  void bodyEl.offsetWidth;
  bodyEl.classList.add("typing");
}

function showNotification(data) {
  if (hideTimer) {
    window.clearTimeout(hideTimer);
    hideTimer = null;
  }

  titleEl.textContent = data.title || "110番入電";
  resetTyping(data.body || "通報あり");

  container.style.display = "block";
  notification.classList.remove("hide");
  void notification.offsetWidth;
  notification.classList.add("show");
}

function hideNotification() {
  notification.classList.remove("show");
  notification.classList.add("hide");
  hideTimer = window.setTimeout(() => {
    container.style.display = "none";
    notification.classList.remove("hide");
    bodyEl.classList.remove("typing");
    bodyEl.classList.add("done");
    hideTimer = null;
  }, 300);
}

bodyEl.addEventListener("animationend", (event) => {
  if (event.animationName === "typing") {
    bodyEl.classList.remove("typing");
    bodyEl.classList.add("done");
  }
});

window.addEventListener("message", (event) => {
  const data = event.data || {};
  switch (data.type) {
    case "show110":
      showNotification(data);
      break;
    case "hide":
      hideNotification();
      break;
    default:
      break;
  }
});
