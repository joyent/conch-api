var m = require("mithril");
var Auth = require("../models/Auth");

module.exports = {
    view: function() {
        return m(".login-view", m("form.pure-form", [
            m("legend", "Login to Conch"),
            m("input[type=text][placeholder=User Name]", {
                oninput: m.withAttr("value", Auth.setUsername),
                value: Auth.username}),
            m("input[type=password][placeholder=PIN]", {
                oninput: m.withAttr("value", Auth.setPassword),
                value: Auth.password}),
            m("button[type=submit].pure-button.pure-button-primary", {
                onclick: Auth.login},
              "Login")]));
    }
};
