var m = require("mithril");
var t = require('i18n4v');

module.exports = {
    view: function(vnode) {
        return m("main.layout", [
            m(".pure-g", [
              m(".pure-u-1-12.pure-menu.nav",
                m("ul.pure-menu-list",[
                  m("li.pure-menu-item.nav-item",
                    m("a[href='/rack'].pure-menu-link",
                      {oncreate: m.route.link}, t("Racks"))
                  ),
                  m("li.pure-menu-item.nav-item",
                    m("a[href='/problem'].pure-menu-link",
                      {oncreate: m.route.link}, t("Problems"))
                  ),
                  m("li.pure-menu-item.nav-item",
                    m("a[href='/device'].pure-menu-link",
                      {oncreate: m.route.link}, t("Devices"))
                  ),
                ]
                )),
                vnode.children
            ]),
        ]);
    }
};
