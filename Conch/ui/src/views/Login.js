import m from "mithril";
import Auth from "../models/Auth";
import t from "i18n4v";

export default {
    view() {
        return m(
            ".login-view",
            m("form.pure-form", [
                m("legend", t("Login to Conch")),
                m("input[type=text]", {
                    oninput: m.withAttr("value", Auth.setUsername),
                    placeholder: t("User Name"),
                    value: Auth.username,
                }),
                m("input[type=password]", {
                    oninput: m.withAttr("value", Auth.setPassword),
                    placeholder: t("Password"),
                    value: Auth.password,
                }),
                m(
                    "button[type=submit].pure-button.pure-button-primary",
                    {
                        onclick(e) {
                            e.preventDefault();
                            Auth.login();
                        },
                    },
                    t("Login")
                ),
            ]),
            m(
                "button.pure-button",
                {
                    onclick() {
                        t.selectLanguage(["en", "ko", "ko-KR"], (err, lang) => {
                            if (!lang || lang === "en") {
                                t.setLanguage("ko");
                            } else {
                                t.setLanguage("en");
                            }
                            location.reload();
                        });
                    },
                },
                t("Toggle Language")
            )
        );
    },
};
