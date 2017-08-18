var m = require("mithril");
var t = require("i18n4v");

var Problem = require("../models/Problem");
var Rack = require("../models/Rack");
var Table = require("./component/Table");


function categoryTitle(category) {
    switch (category) {
        case 'failing':
            return t("Validation Failed");
        case 'unlocated':
            return t("No Location Assigned");
        case 'unreported':
            return t("No Device Report Collected");
        default:
            return t("Other Problems");
    }
}

var selectProblemDevice = {
    oninit: Problem.loadDeviceProblems,
    view: function(vnode) {
        return Object.keys(Problem.devices).map(function(category) {
            var devices = Problem.devices[category];
            return [
                m("h4.selection-list-header", categoryTitle(category)),
                m(".selection-list-group", Object.keys(devices).map(
                    function(deviceId) {
                        return m("a.selection-list-item",
                            {
                                href: "/problem/" + deviceId,
                                onclick: function() {
                                    Problem.selected = devices[deviceId];
                                },
                                oncreate: m.route.link
                            },
                            m(".pure-g", [ m(".pure-u-1", t("Device") + " " + deviceId) ])
                        );
                    })
                )
            ];
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
        var reportTable = Problem.selected.problems ?
            Table(t("Validation Failures"),
            [
                t("Component Type"),
                t("Component Name"),
                t("Condition"),
                t("Log"),
            ],
                Problem.selected.problems.map(function(problem){
                    return [
                        problem.component_type,
                        problem.component_name,
                        problem.criteria.condition,
                        problem.log
                    ];
                })
            )
            : Problem.selected.report_id ?
                null
                : m("h2.text-center", t("Device has not sent a report"));
        var reportButton = Problem.selected.report_id ?
                m("a.pure-button",
                    {
                        href: "/device/" + vnode.attrs.id,
                        oncreate: m.route.link
                    },
                    t("Show Device Report")
                )
                : null;

        var deviceLocation = Problem.selected.location ?
            Table(t("Device Location"),
            [
                t("Datacenter"),
                t("Rack"),
                t("Role"),
                t("Unit"),
            ], [[
                Problem.selected.location.datacenter.name,
                Problem.selected.location.rack.name,
                Problem.selected.location.rack.role,
                Problem.selected.location.rack.unit,
            ]])
            : m("h2.text-center", t("Device has not been assigned a location"));
        var locationButton = Problem.selected.location ?
                m("a.pure-button",
                    {
                        href: "/rack/" + Problem.selected.location.rack.id +
                        "?device=" + vnode.attrs.id,
                        oncreate: m.route.link
                    },
                    t("Show Device in Rack")
                )
                : null;

        return m(".pure-g", [
            m(".pure-u-1", reportTable),
            m(".pure-u-1.text-center", reportButton),
            m(".pure-u-1", deviceLocation),
            m(".pure-u-1.text-center", locationButton)
        ]);
    }
};


module.exports = {
    selectProblemDevice : selectProblemDevice,
    makeSelection       : makeSelection,
    showDevice          : showDevice
};
