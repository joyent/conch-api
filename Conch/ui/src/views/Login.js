import m from "mithril";
import Auth from "../models/Auth";
import Workspace from "../models/Workspace";
import t from "i18n4v";

export default {
    view({ state }) {
        return m(
            ".login-view",
            m("form.pure-form", [
                m("legend", t("Login to Conch")),
                state.badLogin &&
                    m(".pure-u-1", t("Incorrect email address or password")),
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
                            Auth.login().then(loggedIn => {
                                if (loggedIn) {
                                    state.badLogin = false;
                                    Workspace.loadWorkspaces().then(_ =>
                                        m.route.set("/")
                                    );
                                } else {
                                    state.badLogin = true;
                                }
                            });
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
