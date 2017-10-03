var m = require("mithril");
var t = require("i18n4v");

var Problem = require("../models/Problem");
var Rack = require("../models/Rack");
var Table = require("./component/Table");

function categoryTitle(category) {
    switch (category) {
        case "failing":
            return t("Validation Failed");
        case "unlocated":
            return t("No Location Assigned");
        case "unreported":
            return t("No Device Report Collected");
        default:
            return t("Other Problems");
    }
}

var selectProblemDevice = {
    loading: true,
    oninit: ({ state }) =>
        Problem.loadDeviceProblems().then(() => (state.loading = false)),
    view: ({ state, attrs }) => {
        if (state.loading) return m(".loading", "Loading...");

        return Object.keys(Problem.devices).map(function(category) {
            var devices = Problem.devices[category];
            return [
                m("h4.selection-list-header", categoryTitle(category)),
                m(
                    ".selection-list-group",
                    Object.keys(devices).map(function(deviceId) {
                        // Assign the current device if it matches the URL parameter
                        if (attrs.id && attrs.id === deviceId)
                            Problem.current = devices[deviceId];

                        return m(
                            "a.selection-list-item",
                            {
                                href: "/problem/" + deviceId,
                                onclick: function() {
                                    Problem.current = devices[deviceId];
                                },
                                oncreate: m.route.link,
                            },
                            m(".pure-g", [
                                m(".pure-u-1", t("Device") + " " + deviceId),
                            ])
                        );
                    })
                ),
            ];
        });
    },
};

var makeSelection = {
    view: function() {
        return m(".make-selection", t("Select Device"));
    },
};

var showDevice = {
    oninit: function(vnode) {},
    view: function(vnode) {
        if (!Problem.current) return m(".make-selection", t("Select Device"));
        var reportTable = Problem.current.problems
            ? Table(
                  t("Validation Failures"),
                  [
                      t("Component Type"),
                      t("Component Name"),
                      t("Condition"),
                      t("Log"),
                  ],
                  Problem.current.problems.map(function(problem) {
                      return [
                          problem.component_type,
                          problem.component_name,
                          problem.criteria.condition,
                          problem.log,
                      ];
                  })
              )
            : Problem.current.report_id
              ? null
              : m("h2.text-center", t("Device has not sent a report"));
        var reportButton = Problem.current.report_id
            ? m(
                  "a.pure-button",
                  {
                      href: "/device/" + vnode.attrs.id,
                      oncreate: m.route.link,
                  },
                  t("Show Device Report")
              )
            : null;

        var deviceLocation = Problem.current.location
            ? Table(
                  t("Device Location"),
                  [t("Datacenter"), t("Rack"), t("Role"), t("Unit")],
                  [
                      [
                          Problem.current.location.datacenter.name,
                          Problem.current.location.rack.name,
                          Problem.current.location.rack.role,
                          Problem.current.location.rack.unit,
                      ],
                  ]
              )
            : m("h2.text-center", t("Device has not been assigned a location"));
        var locationButton = Problem.current.location
            ? m(
                  "a.pure-button",
                  {
                      href:
                          "/rack/" +
                          Problem.current.location.rack.id +
                          "?device=" +
                          vnode.attrs.id,
                      oncreate: m.route.link,
                  },
                  t("Show Device in Rack")
              )
            : null;

        return m(".pure-g", [
            m(".pure-u-1", reportTable),
            m(".pure-u-1.text-center", reportButton),
            m(".pure-u-1", deviceLocation),
            m(".pure-u-1.text-center", locationButton),
        ]);
    },
};

module.exports = {
    selectProblemDevice: selectProblemDevice,
    makeSelection: makeSelection,
    showDevice: showDevice,
};
