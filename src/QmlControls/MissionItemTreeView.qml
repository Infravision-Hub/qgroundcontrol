import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

/// Unified plan tree view showing Mission Items, GeoFence, and Rally Points
/// as collapsible sections using a real TreeView with type-discriminating delegates.
TreeView {
    id: root

    required property var editorMap
    required property var planMasterController

    property var _missionController: planMasterController.missionController
    property var _geoFenceController: planMasterController.geoFenceController
    property var _rallyPointController: planMasterController.rallyPointController

    model: _missionController.visualItemsTree
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    reuseItems: false
    pointerNavigationEnabled: false
    selectionBehavior: TableView.SelectionDisabled
    rowSpacing: 2

    // QGCFlickableScrollIndicator expects parent to have indicatorColor (provided by QGCFlickable/QGCListView)
    property color indicatorColor: qgcPal.text

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    QGCFlickableScrollIndicator { parent: root; orientation: QGCFlickableScrollIndicator.Horizontal }
    QGCFlickableScrollIndicator { parent: root; orientation: QGCFlickableScrollIndicator.Vertical }

    Component.onCompleted: {
        // Expand only Mission Items by default
        root.expand(0)
    }

    Connections {
        target: root._missionController
        function onVisualItemsChanged() {
            // Mission group always expanded after rebuild (clear / load)
            root.collapseRecursively()
            root.expand(0)
            _editingLayer = _layerMission
        }
    }

    // Switching editing layer on group expand — exclusive: only one group expanded at a time
    function _expandExclusive(clickedNodeType) {
        // Collapse everything
        root.collapseRecursively()

        // Determine target visual row and editing layer from nodeType
        // After full collapse, groups are always at rows 0, 1, 2
        var targetRow = -1
        if (clickedNodeType === "missionGroup") {
            targetRow = 0
            _editingLayer = _layerMission
        } else if (clickedNodeType === "fenceGroup") {
            targetRow = 1
            _editingLayer = _layerFence
        } else if (clickedNodeType === "rallyGroup") {
            targetRow = 2
            _editingLayer = _layerRally
        }

        if (targetRow >= 0) {
            root.expand(targetRow)
        }
    }

    // Coalesces multiple delegate height changes into a single forceLayout() call
    Timer {
        id: layoutTimer
        interval: 0
        running: false
        repeat: false
        onTriggered: root.forceLayout()
    }

    delegate: Item {
        id: delegateRoot

        required property TreeView treeView
        required property bool isTreeNode
        required property bool expanded
        required property bool hasChildren
        required property int depth
        required property int row
        required property var model

        readonly property var nodeObject: model.object
        readonly property string nodeType: model.nodeType

        implicitWidth: root.width
        implicitHeight: loader.item ? loader.item.height : 0
        width: root.width
        height: implicitHeight

        onImplicitHeightChanged: layoutTimer.restart()

        Loader {
            id: loader
            width: parent.width
            sourceComponent: {
                switch (delegateRoot.nodeType) {
                case "missionGroup":    return groupHeaderComponent
                case "fenceGroup":      return groupHeaderComponent
                case "rallyGroup":      return groupHeaderComponent
                case "missionItem":     return missionItemComponent
                case "fenceEditor":     return fenceEditorComponent
                case "rallyHeader":     return rallyHeaderComponent
                case "rallyItem":       return rallyItemComponent
                default:                return null
                }
            }
        }

        // ── Group header (Mission Items / GeoFence / Rally Points) ──
        Component {
            id: groupHeaderComponent

            Rectangle {
                width:  delegateRoot.width
                height: groupHeaderRow.height + ScreenTools.defaultFontPixelHeight * 0.5
                color:  _isActiveGroup ? qgcPal.buttonHighlight : qgcPal.windowShade

                property bool _isActiveGroup: {
                    if (delegateRoot.nodeType === "missionGroup") return _editingLayer === _layerMission
                    if (delegateRoot.nodeType === "fenceGroup")   return _editingLayer === _layerFence
                    if (delegateRoot.nodeType === "rallyGroup")   return _editingLayer === _layerRally
                    return false
                }

                Row {
                    id: groupHeaderRow
                    spacing: ScreenTools.defaultFontPixelWidth * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left:           parent.left
                    anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 0.5

                    QGCLabel {
                        text: delegateRoot.expanded ? "\u25BE" : "\u25B8"
                        color: parent.parent._isActiveGroup ? qgcPal.buttonHighlightText : qgcPal.text
                        font.pointSize: ScreenTools.defaultFontPointSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    QGCLabel {
                        text: delegateRoot.nodeObject ? delegateRoot.nodeObject.objectName : ""
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: parent.parent._isActiveGroup ? qgcPal.buttonHighlightText : qgcPal.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root._expandExclusive(delegateRoot.nodeType)
                }
            }
        }

        // ── Mission item delegate ──
        Component {
            id: missionItemComponent

            MissionItemEditor {
                width: delegateRoot.width
                map: root.editorMap
                masterController: root.planMasterController
                missionItem: delegateRoot.nodeObject
                readOnly: false

                onClicked:  root._missionController.setCurrentPlanViewSeqNum(delegateRoot.nodeObject.sequenceNumber, false)

                onRemove: {
                    var viIndex = root._missionController.visualItemIndexForObject(delegateRoot.nodeObject)
                    if (viIndex > 0) {
                        root._missionController.removeVisualItem(viIndex)
                    }
                }

                onSelectNextNotReadyItem: {
                    for (var i = 0; i < root._missionController.visualItems.count; i++) {
                        var vmi = root._missionController.visualItems.get(i)
                        if (vmi.readyForSaveState === VisualMissionItem.NotReadyForSaveData) {
                            root._missionController.setCurrentPlanViewSeqNum(vmi.sequenceNumber, true)
                            break
                        }
                    }
                }
            }
        }

        // ── GeoFence editor (single child of fence group) ──
        Component {
            id: fenceEditorComponent

            GeoFenceEditor {
                width: delegateRoot.width
                myGeoFenceController: root._geoFenceController
                flightMap: root.editorMap
            }
        }

        // ── Rally header / instructions ──
        Component {
            id: rallyHeaderComponent

            RallyPointEditorHeader {
                width: delegateRoot.width
                controller: root._rallyPointController
            }
        }

        // ── Rally point item editor ──
        Component {
            id: rallyItemComponent

            RallyPointItemEditor {
                width: delegateRoot.width
                rallyPoint: delegateRoot.nodeObject
                controller: root._rallyPointController
            }
        }
    }
}
