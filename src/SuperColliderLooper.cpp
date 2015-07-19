#include "SuperColliderLooper.h"


SuperColliderLoopElement::SuperColliderLoopElement(SuperCollider * sc3, int numBeats, int index){
    int BPM = 120;
    
    this->numBeats = numBeats;
    this->volume = 1.0;
    this->skip = 1;
    this->count = 0;
    this->solo = false;
    this->mute = false;
    
    // supercollider stuff
    buffer = sc3->addBuffer("buffer"+ofToString(ofRandom(10000)), 44100 * (numBeats * 60.0f / BPM), 1);
    bufWriter = sc3->addSynth("buf_recorder");
    bufReader = sc3->addSynth("buf_player");
    bufWriter->set("bufnum", buffer->index);
    bufReader->set("bufnum", buffer->index);
    
    // create gui
    vector<string> inputItems, skipItems;
    inputItems.push_back("1");
    inputItems.push_back("2");
    skipItems.push_back("1");
    skipItems.push_back("2");
    skipItems.push_back("4");
    skipItems.push_back("8");
    gui = new ofxUICanvas("Track");
    gui->setPosition(5, 55 + 32 * index);
    gui->clearWidgets();
    gui->addLabel("Channel:");
    gui->setWidgetPosition(OFX_UI_WIDGET_POSITION_RIGHT);
    gui->addRadio("BusIn", inputItems, OFX_UI_ORIENTATION_HORIZONTAL)->getToggles()[0]->setValue(true);
    gui->addLabel("Play:");
    gui->addLabelToggle("Play", &isPlay, 42.0f);
    gui->addLabelToggle("Rec", &toRecord, 42.0f);
    gui->addLabelToggle("Solo", &solo, 42.0f);
    gui->addLabelButton("Del", false, 42.0f);
    gui->addLabel("Each:");
    gui->addRadio("Skip", skipItems, OFX_UI_ORIENTATION_HORIZONTAL)->getToggles()[0]->setValue(true);
    gui->addMinimalSlider("Volume", 0.0f, 1.0f, &volume, 60.0f, 16.0f);
    gui->addLabel("Time:");
    progressSlider = gui->addMinimalSlider("", 0.0, 1.0, 0.0);
    progressSlider->getRect()->setWidth(20 * numBeats);
    gui->autoSizeToFitWidgets();
    gui->getRect()->setWidth(ofGetWidth()-10);
    ofAddListener(gui->newGUIEvent, this, &SuperColliderLoopElement::guiEvent);
    setPlaying(false);
    setRecording(false);
}

void SuperColliderLoopElement::guiEvent(ofxUIEventArgs &e) {
    if (e.getName() == "Play") {
        setPlaying(isPlay);
    }
    else if (e.getName() == "Rec") {
        setToRecord(toRecord);
    }
    else if (e.getName() == "Solo") {
        setSolo(solo);
        SuperColliderLoopElement *ref = this;
        ofNotifyEvent(soloEvent, ref);
    }
    else if (e.getName() == "Del") {
        SuperColliderLoopElement *ref = this;
        ofNotifyEvent(deleteEvent, ref);
    }
    else if (e.getName() == "Skip") {
        skip = pow((float) 2, (float) ((ofxUIRadio *) gui->getWidget("Skip"))->getValue());
        count = beat % (numBeats * getSkip());
    }
    else if (e.getName() == "BusIn") {
        int channel = ((ofxUIRadio *) gui->getWidget("BusIn"))->getValue();
        bufWriter->set("channel", channel);
    }
    else if (e.getName() == "Volume") {
        
    }
}

void SuperColliderLoopElement::setBeat(int beat) {
    this->beat = beat;
    if (beat % getNumBeats() == 0 && getPlaying())
    {
        count = (count + 1) % getSkip();
        if (count % (numBeats * getSkip()) == 0) {
            if (!mute) play();
            count = 0;
        }
    }
    
    if (beat == 0 && getToRecord()) {
        beginRecording();
    }
    else if (isRecord && (beat >= numBeats || beat == 0)) {
        setRecording(false);
    }
}

void SuperColliderLoopElement::setSolo(bool solo) {
    this->solo = solo;
    if (solo)   mute = false;
    ((ofxUILabelToggle *) gui->getWidget("Solo"))->setValue(solo);
}

void SuperColliderLoopElement::setMute(bool mute) {
    this->mute = mute;
}

void SuperColliderLoopElement::update(float t) {
    progressSlider->setValue(((isPlay && !mute && count == 0) | (isRecord && beat < numBeats)) ? (float) fmodf(t, (float) numBeats) / numBeats : 0);
}

void SuperColliderLoopElement::setPlaying(bool isPlay) {
    this->isPlay = isPlay;
}

void SuperColliderLoopElement::setToRecord(bool toRecord) {
    this->toRecord = toRecord;
}

void SuperColliderLoopElement::setRecording(bool isRecord) {
    this->isRecord = isRecord;
    progressSlider->setColorFill(isRecord ? ofColor::red : ofColor::green);
}

void SuperColliderLoopElement::beginRecording() {
    setRecording(true);
    buffer->alloc();
    bufWriter->create();
    toRecord = false;
    t0 = 0;
}

void SuperColliderLoopElement::play() {
    bufReader->grain();
}


void SuperColliderLooper::setup(SuperCollider *sc3) {
    this->sc3 = sc3;
    bpm = 120;
    click = false;
    
    soundClick.loadSound("/Users/gene/Audio/Sounds/15__tictacshutup__household-percussion/407__tictacshutup__click-1-off-click.wav");
    
    gui = new ofxUICanvas("Track");
    gui->setPosition(5, 5);
    gui->clearWidgets();
    gui->addIntSlider("Bpm", 1, 480, &bpm, 90.0f, 16.0f);
    gui->setWidgetPosition(OFX_UI_WIDGET_POSITION_RIGHT);
    gui->addLabelToggle("Click", &click, 60.0f);
    gui->addLabelToggle("Record", false, 60.0f);
    vector<string> items;
    for (int i=0; i<16; i++) items.push_back(ofToString(i+1));
    gui->addLabel("Beat:");
    guiBeat = gui->addRadio("Beat", items, OFX_UI_ORIENTATION_HORIZONTAL);
    gui->addLabel("Add:");
    gui->addLabelButton("+1", false, 24.0f);
    gui->addLabelButton("+2", false, 24.0f);
    gui->addLabelButton("+4", false, 24.0f);
    gui->addLabelButton("+8", false, 24.0f);
    gui->addLabelButton("+16", false, 32.0f);
    gui->autoSizeToFitWidgets();
    gui->setWidth(ofGetWidth() - 10);
    ofAddListener(gui->newGUIEvent, this, &SuperColliderLooper::guiEvent);
    
    setBpm(120);
    clock.start();
    ofAddListener(clock.beatEvent, this, &SuperColliderLooper::beatEvent);
}

void SuperColliderLooper::setBpm(int bpm) {
    this->bpm = bpm;
    clock.setBpm(bpm);
    clock.setBeatPerBar(4);
    timeInterval = 60.0 / bpm;
}

void SuperColliderLooper::beatEvent(){
    beat = (beat + 1) % 16;
    timeLast = ofGetElapsedTimef();
    guiBeat->getToggles()[(beat+15)%16]->setValue(false);
    guiBeat->getToggles()[beat]->setValue(true);
    
    if (click) {
        soundClick.play();
    }
    
    for (auto e : elements) {
        e->setBeat(beat);
    }
}

void SuperColliderLooper::guiEvent(ofxUIEventArgs &evt) {
    if (evt.getName() == "Bpm") {
        setBpm(bpm);
    }
    else if (evt.getName() == "Record") {
        string filename = ofSystem("Filename");
    }
    else if (evt.getName() == "+1" && ((ofxUILabelButton *) gui->getWidget("+1"))->getValue()) {
        addNewElement(1, elements.size());
    }
    else if (evt.getName() == "+2" && ((ofxUILabelButton *) gui->getWidget("+2"))->getValue()) {
        addNewElement(2, elements.size());
    }
    else if (evt.getName() == "+4" && ((ofxUILabelButton *) gui->getWidget("+4"))->getValue()) {
        addNewElement(4, elements.size());
    }
    else if (evt.getName() == "+8" && ((ofxUILabelButton *) gui->getWidget("+8"))->getValue()) {
        addNewElement(8, elements.size());
    }
    else if (evt.getName() == "+16" && ((ofxUILabelButton *) gui->getWidget("+16"))->getValue()) {
        addNewElement(16, elements.size());
    }
}

void SuperColliderLooper::addNewElement(int numBeats, int index) {
    SuperColliderLoopElement *newElement = new SuperColliderLoopElement(sc3, numBeats, index);
    elements.push_back(newElement);
    ofAddListener(newElement->soloEvent, this, &SuperColliderLooper::eventSolo);
    ofAddListener(newElement->deleteEvent, this, &SuperColliderLooper::eventDelete);
}

void SuperColliderLooper::eventSolo(SuperColliderLoopElement* &evt) {
    if (evt->getSolo()) {
        for (auto e : elements) {
            if (e == evt) {
                e->setSolo(true);
            }
            else {
                e->setSolo(false);
                e->setMute(true);
            }
        }
    }
    else {
        for (auto e : elements) {
            e->setMute(false);
        }
    }
}

void SuperColliderLooper::eventDelete(SuperColliderLoopElement* &evt) {
    for (auto e : elements) {
        if (e == evt) {
            cout << "found this del one " <<endl;
        }
    }
}

void SuperColliderLooper::update(){
    float t = beat + (float) (ofGetElapsedTimef() - timeLast) / timeInterval;
    for (auto e : elements) {
        e->update(t);
    }
    ofSoundUpdate();
}