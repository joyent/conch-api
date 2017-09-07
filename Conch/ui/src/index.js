var m = require("mithril");
var t = require('i18n4v');

var Device      = require("./views/Device");
var Layout      = require("./views/Layout");
var Login       = require("./views/Login");
var Problem     = require("./views/Problem");
var Rack        = require("./views/Rack");
var Status      = require("./views/Status");
var RelayList   = require("./views/Relay/List");
var RelayDetail = require("./views/Relay/Detail");

var korean = require('./languages/ko.js');
const languages = {
    en: require('./languages/en.js'),
    ko: korean,
    'ko-KR': korean
};

t.selectLanguage(['en', 'ko', 'ko-KR'], function (err, lang) {
    t.translator.add(languages[lang] ? languages[lang] : languages.en);
});


m.route(document.body, "/", {
    "/" : {
        render: function() {
            return m(Layout.twoPane, { active: 0, title : "Status"},
                m(Status)
            );
        }
    },
    "/status" : {
        render: function() {
            return m(Layout.twoPane, { active: 1, title : "Status"},
                m(Status)
            );
        }
    },
    "/rack": {
        render: function() {
            return m(Layout.threePane, { active : 1, title: "Racks"  },
              m(Rack.allRacks),
              m(Rack.makeSelection)
            );
        }
    },
    "/rack/:id": {
        render: function(vnode) {
            return m(Layout.threePane, { active : 2, title: "Rack"  },
                m(Rack.allRacks),
                m(Rack.rackLayout, vnode.attrs)
            );
        }
    },
    "/problem": {
        render: function(vnode) {
            return m(Layout.threePane, { active : 1, title: "Problems"  },
                m(Problem.selectProblemDevice),
                m(Problem.makeSelection)
            );
        }
    },
    "/problem/:id": {
        render: function(vnode) {
            return m(Layout.threePane, { active : 2, title: "Problem"  },
                m(Problem.selectProblemDevice),
                m(Problem.showDevice, vnode.attrs)
            );
        }
    },
    "/device": {
        render: function(vnode) {
            return m(Layout.threePane, { active : 1, title: "Device Reports"  },
                m(Device.allDevices),
                m(Device.makeSelection)
            );
        }
    },
    "/device/:id": {
        render: function(vnode) {
            return m(Layout.threePane, { active : 2, title: "Report"  },
                m(Device.allDevices),
                m(Device.deviceReport, vnode.attrs)
            );
        }
    },
    "/relay" : {
        render : (vnode) => {
            return m(Layout.threePane, { active : 1, title: "Relays"  },
                m(RelayList),
                m(RelayDetail)
            );
        }
    },
    "/relay/:id" : {
        render : ({attrs}) => {
            return m(Layout.threePane, { active : 2, title: "Relay"  },
                m(RelayList, attrs),
                m(RelayDetail, attrs)
            );
        }
    },
    "/login": Login
});
