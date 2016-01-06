class ControlFrame extends PApplet {

  int w, h;
  PApplet parent;
  ControlP5 cp5;

  Textfield myTextfield;

  public ControlFrame(PApplet _parent, int _w, int _h, String _name) {
    super();   
    parent = _parent;
    w=_w;
    h=_h;
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  public void setup() {
    this.surface.setSize(w, h);
    createControls ();
  }

  public void draw () {
    background (0);
  }

  public void createControls () {
    cp5 = new ControlP5(this);

    myTextfield = cp5.addTextfield("")
      .setPosition(20, 20)
      .setSize(200, 20)
      .setFocus(true);
  }

  public String getText () {
    if (myTextfield != null) {
      return myTextfield.getText ();
    }
    return "";
  }
}