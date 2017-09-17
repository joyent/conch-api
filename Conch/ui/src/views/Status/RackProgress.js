import m from 'mithril';
import * as d3 from "d3";
import RelationshipGraph from "d3-relationshipgraph";

var Rack   = require("../../models/Rack");

export default function RackProgress({attr}) {
    return {
        view : () => {
                var stat = ['Ready', 'Validating', 'Failing', 'Not Reporting'];
                var i = 0;
            const rackStatus = Object.keys(Rack.rackRooms).reduce((acc, room) => {
                Rack.rackRooms[room].forEach((rack) => {
                    acc.push(
                        {
                            'Room' : room,
                            'Rack Name' : rack.name,
                            'Rack Role' : rack.role,
                            'Rack size' : rack.size,
                            parent: stat[i%4],
                            value : rack.size,
                            _private_ : {
                                id : rack.id
                            }
                        }
                    );
                    i++;
                });
                return acc;
            }, []);
            return m(".rack-progress-graph", {
                oncreate : ({dom, state}) => {
                    if (rackStatus) {
                        new RelationshipGraph(d3.select(dom), {
                            showTooltips: true,
                            maxChildCount: 10,
                            showKeys: true,
                            thresholds: [0, 50, 100],
                            colors: ['hsl(225, 20%, 70%)', 'hsl(225, 80%, 90%)', 'hsl(130, 80%, 90%)'],
                            onClick : {
                                child : (rack) => {
                                    m.route.set('/rack/'+rack._private_.id);
                                }
                            }
                        }).data(rackStatus);
                    }
                },
                onremove : ({dom, state}) => {
                    // RelationshipGraph creates a d3Tip object which adds a
                    // svg to the body. This isn't cleaned up when the node is
                    // removed, leaving a junk SVG block elmeent that screws
                    // with the layout. 
                    d3.selectAll("svg").remove();
                }
            });
        }
    };

}
