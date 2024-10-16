// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = {};

Hooks.Select = {
  // https://aurmartin.fr/posts/phoenix-liveview-select/
  mounted() {
    this.selectMenu = this.el.querySelector(`#${this.el.id}_select`);
    this.valueInput = this.el.querySelector(`#${this.el.id}_value_input`);
    this.textInput = this.el.querySelector(`#${this.el.id}_input`);

    // Initialize internal statee
    this.isOpen = false;
    this.activeOptionIndex = -1;
    this.selected = {
      value: this.valueInput.value,
      text: this.textInput.value,
    };

    // State transformation functions
    this.close = () => {
      this.isOpen = false;
      this.selectMenu.classList.add("hidden");
    };
    this.open = () => {
      this.isOpen = true;
      this.selectMenu.classList.remove("hidden");
    };
    this.setActiveElementIndex = (index) => {
      const optionElements = this.selectMenu.querySelectorAll("[data-id]");

      if (optionElements[this.activeOptionIndex])
        optionElements[this.activeOptionIndex].classList.remove("bg-slate-100");

      if (index < 0) {
        this.activeOptionIndex = optionElements.length - 1;
      } else if (index >= optionElements.length) {
        this.activeOptionIndex = 0;
      } else {
        this.activeOptionIndex = index;
      }
      optionElements[this.activeOptionIndex].classList.add("bg-slate-100");
    };
    this.onItemSelect = (e) => {
      // Get value and text from data-* attributes
      this.selected = {
        value: e.target.dataset.id,
        text: e.target.dataset.text,
      };

      // Display the selected option in the input
      this.textInput.value = this.selected.text;

      // Update the hidden input value and dispatch a change event
      this.valueInput.value = this.selected.value;
      this.valueInput.dispatchEvent(new Event("change", { bubbles: true }));

      this.close();
    };

    // Event listeners
    this.textInput.addEventListener("focus", this.open);
    this.textInput.addEventListener("blur", this.close);
    this.textInput.addEventListener("keydown", (e) => {
      e.stopPropagation();

      if (e.key === "Escape") {
        this.close();
      } else if (e.key === "ArrowDown") {
        this.setActiveElementIndex(this.activeOptionIndex + 1);
      } else if (e.key === "ArrowUp") {
        this.setActiveElementIndex(this.activeOptionIndex - 1);
      } else if (e.key === "Enter" && this.isOpen) {
        if (this.activeOptionIndex >= 0) {
          const activeOption =
            this.selectMenu.querySelectorAll("[data-id]")[
              this.activeOptionIndex
            ];
          this.onItemSelect({ target: activeOption });
        }
      } else if (!this.isOpen) {
        this.open();
      }
    });
    this.selectMenu.querySelectorAll("[data-id]").forEach((option) => {
      option.addEventListener("mousedown", this.onItemSelect);
    });

    this.textInput.addEventListener("input", (e) => {
      this.pushEvent(this.el.getAttribute("autocomplete"), {
        query: this.textInput.value,
      });
    });
  },
  updated() {
    if (this.isOpen) {
      this.selectMenu.classList.remove("hidden");
    } else {
      this.selectMenu.classList.add("hidden");
    }

    this.valueInput.value = this.selected.value;

    this.selectMenu.querySelectorAll("[data-id]").forEach((option) => {
      option.addEventListener("mousedown", this.onItemSelect);
    });
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
