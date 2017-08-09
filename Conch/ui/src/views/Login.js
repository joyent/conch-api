var m = require("mithril");
var Auth = require("../models/Auth");
var t = require('i18n4v');

module.exports = {
    view: function() {
        return m(".login-view", m("form.pure-form", [
            m("legend", t("Login to Conch")),
            m("input[type=text]", {
                oninput: m.withAttr("value", Auth.setUsername),
                placeholder: t("User Name"),
                value: Auth.username
            }),
            m("input[type=password]", {
                oninput: m.withAttr("value", Auth.setPassword),
                placeholder: t("Password"),
                value: Auth.password}),
            m("button[type=submit].pure-button.pure-button-primary", {
                onclick: Auth.login},
              t("Login")
            )
        ]),
            m("button.pure-button", {
                onclick: function() {
                    t.selectLanguage(['en', 'ko', 'ko-KR'], function (err, lang) {
                        if(!lang || lang === 'en') {
                            t.setLanguage('ko');
                        }
                        else {
                            t.setLanguage('en');
                        }
                        location.reload();
                    });
                }
            },
                t("Toggle Language")
            )
        );
    }
};
