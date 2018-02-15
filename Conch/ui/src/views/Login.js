import m from "mithril";
import Auth from "../models/Auth";
import Workspace from "../models/Workspace";
import t from "i18n4v";

export default {
    view() {
        return m(
            ".login-view",
            m("form.pure-form", [
                m("legend", t("Login to Conch")),
                m("input[type=text]", {
                    oninput: m.withAttr("value", Auth.setLoginEmail),
                    placeholder: t("Email Address"),
                    value: Auth.loginEmail,
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
                            try {
                                Auth.login()
                                    .then(_ =>
                                        Workspace.loadWorkspaces()
                                            .then(_ => m.route.set("/"))
                                    );
                            }
                            catch (e) {
                                // TODO: Display login error
                                console.log('Failed login');
                            }
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
