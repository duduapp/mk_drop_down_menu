import 'package:flutter/material.dart';

class MKDropDownMenuController extends ChangeNotifier {
  bool menuIsShowing = false;

  void showMenu() {
    menuIsShowing = true;
    notifyListeners();
  }

  void hideMenu() {
    menuIsShowing = false;
    notifyListeners();
  }

  void toggleMenu() {
    menuIsShowing = !menuIsShowing;
    notifyListeners();
  }
}

class MKDropDownMenu<T extends MKDropDownMenuController>
    extends StatefulWidget {
  MKDropDownMenu(
      {this.barrierColor = Colors.black12,
      this.controller,
      this.headerBuilder,
      this.menuBuilder,
      this.menuMargin = 0.0,
      this.headerKey})
      : assert(headerBuilder != null),
        assert(menuBuilder != null);

  final Color barrierColor;
  final T controller;
  final Widget Function(bool menuIsShowing) headerBuilder;
  final Widget Function() menuBuilder;
  final double menuMargin;
  final GlobalKey headerKey;
  @override
  _MKDropDownMenuState createState() => _MKDropDownMenuState();
}

class _MKDropDownMenuState extends State<MKDropDownMenu>
    with TickerProviderStateMixin {
  var _controller;
  OverlayEntry _overlayEntry;
  GlobalKey _headerKey = GlobalKey();
  AnimationController _acontroller;
  Animation<double> _animation;

  _updateView() {
    if (_controller.menuIsShowing) {
      _showMenu();
    } else {
      _hideMenu();
    }
    setState(() {});
  }

  _buildOverlay() {
    if (_headerKey == null) return;
    RenderBox renderBox;
    if (widget.headerKey != null)
      renderBox = widget.headerKey.currentContext.findRenderObject();
    else
      renderBox = _headerKey.currentContext.findRenderObject();
    Offset offset = renderBox.localToGlobal(Offset.zero);
    double top = renderBox.size.height + offset.dy;
    Rect boxRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: <Widget>[
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (PointerDownEvent event) {
                  // if point in header box, let menu header hide menu
                  if (!boxRect.contains(event.localPosition)) {
                    _controller.hideMenu();
                  }
                },
                child: Container(
                  height: top + widget.menuMargin,
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                child: Material(
                  child: SizeTransition(
                    child: widget.menuBuilder(),
                    sizeFactor: _animation,
                    axis: Axis.vertical,
                    axisAlignment: -1,
                  ),
                  color: Colors.transparent,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _controller.hideMenu,
                  child: Container(
                    color: widget.barrierColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _showMenu() {
    _buildOverlay();

    Overlay.of(context).insert(_overlayEntry);
    OverlayUtil.addOverlay(_overlayEntry);
    _acontroller.forward();
  }

  _hideMenu() {
    if (_overlayEntry != null) {
      _acontroller.reverse().then((value) {
        _overlayEntry.remove();
        _overlayEntry = null;
      });
    }
  }

  @override
  void initState() {
    _controller = widget.controller;
    if (_controller == null) _controller = MKDropDownMenuController();
    _controller.addListener(_updateView);

    _acontroller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _acontroller,
      curve: Curves.linear,
    );

    super.initState();
  }

  @override
  void dispose() {
    _hideMenu();
    _controller.removeListener(_updateView);
    _acontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _controller.toggleMenu,
      child: Container(
        key: _headerKey,
        child: widget.headerBuilder(_controller.menuIsShowing),
      ),
    );
  }
}

class OverlayUtil {
  static List<OverlayEntry> entries = [];

  static addOverlay(OverlayEntry entry) {
    entries.add(entry);
  }

  static hideAllOverlay() {
    for (var entry in entries) {
      try {
        entry?.remove();
      } catch (e) {
        //
      }

    }
    entries.clear();
  }
}
