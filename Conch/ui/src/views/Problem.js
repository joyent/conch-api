var m = require("mithril");
var t = require("i18n4v");
var Problem = require("../models/Problem");
var Rack = require("../models/Rack");

var selectProblemDevice = {
    oninit: Problem.loadDeviceProblems,
    view: function(vnode) {
        return Object.keys(Problem.devices).map(
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
                });
    }
};

var makeSelection = {
    view: function() {
        return m(".make-selection", t("Select Device"));
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

        return m(".pure-g", [
            m(".pure-u-1",
                m("table.pure-table.pure-table-horizontal.pure-table-striped", [
                    m("thead", m("tr", [
                        m("th", t("Component Type")),
                        m("th", t("Component Name")),
                        m("th", t("Condition")),
                        m("th", t("Log")),
                    ])),
                    m("tbody",
                        Problem.selected.problems.map(function(problem){
                            return m("tr", [
                                m("td", {'data-label' : t("Component Type")}, problem.component_type),
                                m("td", {'data-label' : t("Component Name")}, problem.component_name),
                                m("td", {'data-label' : t("Condition")}, problem.criteria.condition),
                                m("td", {'data-label' : t("Log")}, problem.log),
                            ]);
                        })
                    )
                ])
            ),
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
        ]);
    }
};


module.exports = {
    selectProblemDevice : selectProblemDevice,
    makeSelection       : makeSelection,
    showDevice          : showDevice
};
