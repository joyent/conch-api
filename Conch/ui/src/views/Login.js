var m = require("mithril");
var Auth = require("../models/Auth");

module.exports = {
    view: function() {
        return m("form.pure-form", [
            m("input[type=text]", {
                oninput: m.withAttr("value", Auth.setUsername),
                value: Auth.username}),
            m("input[type=password]", {
                oninput: m.withAttr("value", Auth.setPassword),
                value: Auth.password}),
            m("button[type=button].pure-button.pure-button-primary", {
                onclick: Auth.login},
              "Login")]);
    }
};
