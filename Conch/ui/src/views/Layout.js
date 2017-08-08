var m = require("mithril");

module.exports = {
    view: function(vnode) {
        return m("main.layout", [
            m(".pure-g", [
              m(".pure-u-1-12.pure-menu.nav",
                m("ul.pure-menu-list",[
                  m("li.pure-menu-item.nav-item",
                    m("a[href='/rack'].pure-menu-link",
                      {oncreate: m.route.link}, "Racks")
                  ),
                  m("li.pure-menu-item.nav-item",
                    m("a[href='/problem'].pure-menu-link",
                      {oncreate: m.route.link}, "Problems")
                  ),
                  m("li.pure-menu-item.nav-item",
                    m("a[href='/device'].pure-menu-link",
                      {oncreate: m.route.link}, "Devices")
                  ),
                ]
                )),
                vnode.children
            ]),
        ]);
    }
};
