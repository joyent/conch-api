var m = require("mithril");
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
                        // Pluralize when localizing
                        "Device " + deviceId + ": Detected  "
                            + Problem.devices[deviceId].problems.length
                            + " problems."
                    );
                })
            ),
            vnode.children.length > 0
                ? vnode.children
                : m(".make-selection.pure-u-3-4", "Select a device in the sidebar")
        ];
    }
};

var showDevice = {
    oninit: function(vnode) {
        Problem.selectDevice(vnode.attrs.id);
    },
    view: function(vnode) {
        if (!Problem.selected) {
            return m(".pure-u", "Loading...");
        }

        return m(".content-pane.pure-u-3-4",
            m(".pure-g", [
                m(".pure-u-1", [
                    m(".pure-u-1-5", m("h3", "Component Type")),
                    m(".pure-u-1-5", m("h3", "Component Name")),
                    m(".pure-u-1-5", m("h3", "Condition")),
                    m(".pure-u-2-5", m("h3", "Log")),
                ]),
                Problem.selected.problems.map(function(problem){
                    return m(".pure-u-1", m(".pure-g", [
                        m(".pure-u-1-5", problem['component_type']),
                        m(".pure-u-1-5", problem['component_name']),
                        m(".pure-u-1-5", problem.criteria.condition),
                        m(".pure-u-2-5", problem.log),
                    ]));
                }),
                m(".pure-u-1-4",
                    m("a.pure-button",
                        {
                            href: "/device/" + vnode.attrs.id,
                            oncreate: m.route.link
                        },
                        "Show Device Report"
                )),
                m(".pure-u-1-4",
                    m("a.pure-button",
                        {
                            href: "/rack/" + Problem.selected.rack.id 
                                + "?device=" + vnode.attrs.id,
                            oncreate: m.route.link
                        },
                        "Show Device in Rack"
                    )
                )
            ]
            )
        );
    }
};


module.exports =
    { selectProblemDevice : selectProblemDevice,
      showDevice: showDevice
    }
