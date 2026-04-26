function GetParentResourceName() {
  const qs = new URLSearchParams(window.location.search);
  const a = qs.get("resourceName");
  if (a) return a;
  if (window.nuiHandoverData && window.nuiHandoverData.resourceName) {
    return window.nuiHandoverData.resourceName;
  }
  return "jp-koban";
}

function nuiPost(name, data) {
  return fetch("https://" + GetParentResourceName() + "/" + name, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data || {}),
  });
}

const root = document.getElementById("nuiRoot");
const b5el = document.querySelector(".b5");
const b10el = document.querySelector(".b10");

function openModal(d) {
  if (b5el && d && d.bonus5 != null) b5el.textContent = String(d.bonus5);
  if (b10el && d && d.bonus10 != null) b10el.textContent = String(d.bonus10);
  root.classList.remove("nui-hidden");
  root.classList.add("nui-visible");
}

function closeModal() {
  root.classList.remove("nui-visible");
  root.classList.add("nui-hidden");
}

window.addEventListener("message", (e) => {
  const d = e.data;
  if (!d || !d.type) return;
  if (d.type === "open") {
    openModal(d);
  } else if (d.type === "close") {
    closeModal();
  }
});

document.getElementById("btn5").addEventListener("click", () => {
  nuiPost("selectCourse", { count: 5 });
});
document.getElementById("btn10").addEventListener("click", () => {
  nuiPost("selectCourse", { count: 10 });
});
function closeNui() {
  nuiPost("uiClose", {});
}
document.getElementById("btnClose").addEventListener("click", closeNui);
document.getElementById("btnX").addEventListener("click", closeNui);
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && !root.classList.contains("nui-hidden")) {
    closeNui();
  }
});
