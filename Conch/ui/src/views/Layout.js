import m from "mithril";
import t from "i18n4v";
import Auth from "../models/Auth";
import Workspace from "../models/Workspace";
import FeedbackForm from "../views/Feedback";
import Icons from "./component/Icons";

function mainNav(isMobileView, state) {
    return m(
        ".pure-u-1.pure-menu.nav",
        { class: isMobileView ? "mobile-is-active" : "" },

        m("ul.pure-menu-list", [
            m(
                ".pure-menu-heading.text-center.nav-text-color",
                m(".logo"),
                m("h2", t("Conch"))
            ),

            m(
                "li.pure-menu-item.text-center",
                m(".nav-text-color", t("Workspace")),
                m(
                    "select.pure-input-1-2.workspace-select",
                    {
                        onchange() {
                            Workspace.setCurrentId(
                                this[this.selectedIndex].value
                            );
                            location.reload();
                        },
                    },
                    Workspace.list.map(workspace => {
                        let option;
                        if (workspace.id === Workspace.getCurrentId())
                            option = "option[selected=true]";
                        else option = "option";
                        return m(
                            option,
                            { value: workspace.id },
                            workspace.name
                        );
                    })
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a[href='/status'].pure-menu-link.nav-link.nav-text-color",
                    { oncreate: m.route.link },
                    [Icons.nav.status, t("Status")]
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a[href='/rack'].pure-menu-link.nav-link.nav-text-color",
                    { oncreate: m.route.link },
                    [Icons.nav.racks, t("Racks")]
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a[href='/problem'].pure-menu-link.nav-link.nav-text-color",
                    { oncreate: m.route.link },
                    [Icons.nav.problems, t("Problems")]
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a[href='/device'].pure-menu-link.nav-link.nav-text-color",
                    { oncreate: m.route.link },
                    [Icons.nav.devices, t("Devices")]
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a[href='/relay'].pure-menu-link.nav-link.nav-text-color",
                    { oncreate: m.route.link },
                    [Icons.nav.relays, t("Relays")]
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a.pure-menu-link.nav-link.pointer",
                    {
                        onclick() {
                            t.selectLanguage(
                                ["en", "ko", "ko-KR"],
                                (err, lang) => {
                                    if (!lang || lang === "en") {
                                        t.setLanguage("ko");
                                    } else {
                                        t.setLanguage("en");
                                    }
                                    location.reload();
                                }
                            );
                        },
                    },
                    [Icons.nav.language, t("Language")]
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a.pure-menu-link.nav-link.pointer",
                    { onclick: () => (state.showFeedback = true) },
                    [Icons.nav.feedback, t("Feedback")]
                )
            ),

            m(
                "li.pure-menu-item",
                m(
                    "a[href='/login'].pure-menu-link.nav-link",
                    {
                        oncreate: m.route.link,
                        onclick() {
                            Auth.logout();
                        },
                    },
                    [Icons.nav.logout, t("Logout")]
                )
            ),
        ])
    );
}

const mobileNav = {
    view({ attrs }) {
        return m(
            ".mobile-nav.pure-u-1.pure-g",
            m(
                ".pure-u-1-3",
                m(
                    "a.pure-button",
                    {
                        onclick() {
                            const route = m.route.get();
                            const upRoute = route.substring(
                                0,
                                route.lastIndexOf("/")
                            );
                            m.route.set(upRoute);
                        },
                    },
                    "<"
                )
            ),
            m("h2.pure-u-1-3", t(attrs.title)),
            m(".pure-u-1-3", "")
        );
    },
};

// Three-pane layout with two children. Additional children will not be rendered.
const threePane = {
    showFeedback: false,
    view({ attrs, state, children }) {
        return [
            m(".layout", [
                m(".pure-g", [
                    mainNav(attrs.active === 0, state),
                    attrs.active > 0
                        ? m(mobileNav, { title: attrs.title })
                        : null,
                    m(
                        ".selection-list.pure-u-1",
                        {
                            class: attrs.active === 1 ? "mobile-is-active" : "",
                        },
                        children[0]
                    ),
                    m(
                        ".content-pane.pure-u-1",
                        {
                            class: attrs.active === 2 ? "mobile-is-active" : "",
                        },
                        children[1]
                    ),
                ]),
            ]),
            state.showFeedback
                ? m(".modal", m(".modal-dialog", m(FeedbackForm, state)))
                : null,
        ];
    },
};

// Two-pane layout with one child. Additional children will not be rendered.
const twoPane = {
    showFeedback: false,
    view({ attrs, state, children }) {
        return [
            m(".layout", [
                m(".pure-g", [
                    mainNav(attrs.active === 0, state),
                    attrs.active > 0
                        ? m(mobileNav, { title: attrs.title })
                        : null,
                    m(
                        ".content-pane.two-pane.pure-u-1",
                        {
                            class: attrs.active === 1 ? "mobile-is-active" : "",
                        },
                        children[0]
                    ),
                ]),
            ]),
            state.showFeedback
                ? m(".modal", m(".modal-dialog", m(FeedbackForm, state)))
                : null,
        ];
    },
};

export default {
    threePane,
    twoPane,
};
