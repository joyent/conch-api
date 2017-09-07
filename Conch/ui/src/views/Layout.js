var m = require("mithril");
var t = require('i18n4v');

var Auth = require("../models/Auth");
var FeedbackForm = require("../views/Feedback");

function mainNav(isMobileView) {
        return m(".pure-u-1.pure-menu.nav",
            { class: isMobileView ? "mobile-is-active" : "" },

            m("ul.pure-menu-list",[
                m(".pure-menu-heading.nav-text-color", m("h2", t("Conch"))),

                m("li.pure-menu-item",
                    m("a[href='/status'].pure-menu-link.nav-link.nav-text-color",
                        {oncreate: m.route.link}, t("Status"))
                ),

                m("li.pure-menu-item",
                    m("a[href='/rack'].pure-menu-link.nav-link.nav-text-color",
                        {oncreate: m.route.link}, t("Racks"))
                ),

                m("li.pure-menu-item",
                    m("a[href='/problem'].pure-menu-link.nav-link.nav-text-color",
                        {oncreate: m.route.link}, t("Problems"))
                ),

                m("li.pure-menu-item",
                    m("a[href='/device'].pure-menu-link.nav-link.nav-text-color",
                        {oncreate: m.route.link}, t("Devices"))
                ),

                m("li.pure-menu-item",
                    m("a[href='/relay'].pure-menu-link.nav-link.nav-text-color",
                        {oncreate: m.route.link}, t("Relays"))
                ),

                m("li.pure-menu-item",
                    m("a[href='/login'].pure-menu-link.nav-link",
                        {
                            oncreate: m.route.link,
                            onclick: function () {
                                Auth.logout();
                            }
                        }, t("Logout"))
                ),
                m("li.pure-menu-item",
                    m("a[href='#feedback-modal'].pure-menu-link.nav-link", t("Send Feedback"))
                ),

            ])
        );
}

var mobileNav = {
    view: function(vnode) {
        return m(".mobile-nav.pure-u-1.pure-g",
                m(".pure-u-1-3",
                    m("a.pure-button",
                        { onclick: function() {
                            var route = m.route.get();
                            var upRoute = route.substring(0, route.lastIndexOf("/"));
                            m.route.set(upRoute);
                        } },
                        "<"
                    )),
                m("h2.pure-u-1-3",  t(vnode.attrs.title)),
                m(".pure-u-1-3", "")
            );
    }
};


// Three-pane layout with two children. Additional children will not be rendered.
var threePane = {
    view: function(vnode) {
        return [
            m(".layout", [
                m(".pure-g",
                    [
                        mainNav(vnode.attrs.active === 0),
                        vnode.attrs.active > 0 ?
                            m(mobileNav, { title: vnode.attrs.title }) : null,
                        m(".selection-list.pure-u-1",
                            { class: vnode.attrs.active === 1 ? "mobile-is-active" : "" },
                            vnode.children[0]),
                        m(".content-pane.pure-u-1",
                            { class: vnode.attrs.active === 2 ? "mobile-is-active" : "" },
                            vnode.children[1])
                    ]),
            ]),
            m("#feedback-modal.modal", m(".modal-dialog", m(FeedbackForm)))
        ];
    }
};

// Two-pane layout with one child. Additional children will not be rendered.
var twoPane = {
    view: function(vnode) {
        return [
            m(".layout", [
                m(".pure-g",
                    [
                        mainNav(vnode.attrs.active === 0),
                        vnode.attrs.active > 0 ?
                            m(mobileNav, { title: vnode.attrs.title }) : null,
                        m(".content-pane.two-pane.pure-u-1",
                            { class: vnode.attrs.active === 1 ? "mobile-is-active" : "" },
                            vnode.children[0])
                    ]),
            ]),
            m("#feedback-modal.modal", m(".modal-dialog", m(FeedbackForm)))
        ];
    }
};

module.exports = {
    threePane : threePane,
    twoPane   : twoPane
}
