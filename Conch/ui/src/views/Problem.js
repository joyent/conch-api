var m = require("mithril");
var t = require("i18n4v");
var Problem = require("../models/Problem");
var Rack = require("../models/Rack");

var selectProblemDevice = {
    oninit: Problem.loadDeviceProblems,
    view: function(vnode) {
        return [
            m(".selection-list.pure-u-1-6", Object.keys(Problem.devices).map(
                function(deviceId) {
                    return m("a.selection-list-item",
                        {
                            href: "/problem/" + deviceId,
                            onclick: function() {
                                Problem.selected = Problem.devices[deviceId];
                            },
                            oncreate: m.route.link
                        },
                        m(".pure-g", [
                            m(".pure-u-1", t("Device") + " " + deviceId),
                            m(".pure-u-1", t("%n problems found", Problem.devices[deviceId].problems.length))
                        ])
                    );
                })
            ),
            vnode.children.length > 0 ?
                vnode.children
                : m(".make-selection.pure-u-3-4", t("Select Device"))
        ];
    }
};

var showDevice = {
    oninit: function(vnode) {
        Problem.selectDevice(vnode.attrs.id);
    },
    view: function(vnode) {
        if (!Problem.selected) {
            return m(".pure-u", t("Loading") + "...");
        }

        return m(".content-pane.pure-u-3-4",
            m(".pure-g", [
                m(".pure-u-1", [
                    m(".pure-u-1-5", m("h3", t("Component Type"))),
                    m(".pure-u-1-5", m("h3", t("Component Name"))),
                    m(".pure-u-1-5", m("h3", t("Condition"))),
                    m(".pure-u-2-5", m("h3", t("Log"))),
                ]),
                Problem.selected.problems.map(function(problem){
                    return m(".pure-u-1", m(".pure-g", [
                        m(".pure-u-1-5", problem.component_type),
                        m(".pure-u-1-5", problem.component_name),
                        m(".pure-u-1-5", problem.criteria.condition),
                        m(".pure-u-2-5", problem.log),
                    ]));
                }),
                m(".pure-u-1-4",
                    Problem.selected.report_id ?
                        m("a.pure-button",
                            {
                                href: "/device/" + vnode.attrs.id,
                                oncreate: m.route.link
                            },
                            t("Show Device Report")
                        )
                        : ""
                ),
                m(".pure-u-1-4",
                    Problem.selected.rack ?
                        m("a.pure-button",
                            {
                                href: "/rack/" + Problem.selected.rack.id +
                                    "?device=" + vnode.attrs.id,
                                oncreate: m.route.link
                            },
                            t("Show Device in Rack")
                        )
                        : ""
                )
            ]
            )
        );
    }
};


module.exports = {
    selectProblemDevice : selectProblemDevice,
    showDevice          : showDevice
};
