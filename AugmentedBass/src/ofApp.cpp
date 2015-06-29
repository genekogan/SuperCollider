#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    //ofSetWindowShape(480, 560);
    
    buffer = sc3.addBuffer("buffy", 16*44100, 1);
    phaseBus = sc3.addControlBus("phasBus", 1);
    gateBus = sc3.addControlBus("gateBus", 1);
    minSigBus = sc3.addControlBus("minSigBus", 1);
    

    // buffer writer
    bufWriter = sc3.addSynth("bufWriter");
    bufWriter->set("channel", 0);
    bufWriter->set("bufnum", buffer->index);
    bufWriter->set("phasBuf", phaseBus->index);
    bufWriter->set("minSigBus", minSigBus->index);
    bufWriter->set("gateBus", gateBus->index);

    // buffer reader
    bufReader = sc3.addSynth("bufReader");
    bufReader->set("bufnum", buffer->index);
    bufReader->set("phasBuf", phaseBus->index);
    bufReader->set("gateBus", gateBus->index);
    bufReader->set("overlap", 0);
    bufReader->set("outBus", 0);

    // buffer + comb
    comb = sc3.addSynth("bufComb");
    comb->set("bufnum", buffer->index);
    comb->set("phasBuf", phaseBus->index);
    comb->set("gateBus", gateBus->index);
    comb->set("overlap", 0);
    comb->set("outBus", 0);
    comb->set("delayTime", 1.0);
    comb->set("decayTime", 1.0);
    comb->set("gain", 1.0);

    // buffer + allpass
    allpass = sc3.addSynth("bufAllPass");
    allpass->set("bufnum", buffer->index);
    allpass->set("phasBuf", phaseBus->index);
    allpass->set("gateBus", gateBus->index);
    allpass->set("overlap", 0);
    allpass->set("outBus", 0);
    allpass->set("delay", 0.1);
    allpass->set("depth", 0.08);
    allpass->set("rate", 0.06);
    allpass->set("fdbk", 0.0);
    allpass->set("decay", 0.0);
    
    // grains
    grains = sc3.addSynth("bufGrains");
    grains->set("bufnum", buffer->index);
    grains->set("phasBuf", phaseBus->index);
    grains->set("gateBus", gateBus->index);
    grains->set("overlap", 0);
    grains->set("outBus", 0);

    // create
    bufWriter->create();
    
    // gui
    gui = new ofxUICanvas("Augmented Bass");
    gui->addToggle("manual", &isManual);
    gui->addToggle("gate", &manualGate);
    gui->addToggle("overlap", &overlap);
    gui->addSlider("minSigBus", 1, 500, 10);
    gui->addToggle("Playback", &playback);
    //
    guiComb = new ofxUICanvas("Comb");
    guiComb->setPosition(210, 0);
    guiComb->addToggle("On", false);
    guiComb->addSlider("delayTime", 0, 2, 1);
    guiComb->addSlider("decayTime", 0, 2, 1);
    guiComb->addSlider("gain", 0, 4, 1);
    //
    guiAllPass = new ofxUICanvas("Allpass");
    guiAllPass->setPosition(420, 0);
    guiAllPass->addToggle("On", false);
    guiAllPass->addSlider("delayTime", 0, 2, 1);
    guiAllPass->addSlider("decayTime", 0, 2, 1);
    guiAllPass->addSlider("gain", 0, 4, 1);
    guiAllPass->addSlider("delay", 0, 0.3, 0.1);
    guiAllPass->addSlider("depth", 0, 0.2, 0.08);
    guiAllPass->addSlider("rate", 0, 0.2, 0.06);
    guiAllPass->addSlider("fdbk", 0, 1, 0.0);
    guiAllPass->addSlider("decay", 0, 1, 0.0);
    //
    guiGrains = new ofxUICanvas("Grains");
    guiGrains->setPosition(630, 0);
    guiGrains->addToggle("On", false);
    guiGrains->addSlider("position", 0, 1, 0.5);
    guiGrains->addSlider("trate", 1, 200, 20);
    guiGrains->addSlider("width", 1, 40, 12);
    guiGrains->addSlider("dispersion", 0, 1, 0.01);

    ///////
    gui->autoSizeToFitWidgets();
    guiComb->autoSizeToFitWidgets();
    guiAllPass->autoSizeToFitWidgets();
    guiGrains->autoSizeToFitWidgets();
    ofAddListener(gui->newGUIEvent, this, &ofApp::guiEvent);
    ofAddListener(guiComb->newGUIEvent, this, &ofApp::guiCombEvent);
    ofAddListener(guiAllPass->newGUIEvent, this, &ofApp::guiAllPassEvent);
    ofAddListener(guiGrains->newGUIEvent, this, &ofApp::guiGrainsEvent);
    
    isManual = 1;
    manualGate = 0;
    updateManual();
    minSigBus->set(10);
}

//--------------------------------------------------------------
void ofApp::update(){
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofSetColor(255, 0, 0);
    if (isManual && manualGate) {
        ofCircle(ofGetWidth()-100, 100, 100);
    }
    ofSetColor(255);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if (key=='1') {
        isManual = 1;
        manualGate = 1-manualGate;
        cout << "manual gate " << manualGate << " " << isManual << endl;

        bufWriter->set("manual", isManual);
        bufWriter->set("manualGate", manualGate);
    }
    if (key=='2') {
        isManual = 0;

        bufWriter->set("manual", isManual);
        bufWriter->set("manualGate", manualGate);

    }
    
    else if (key=='z') {
        bufReader->set("delay", 0.04);
        bufReader->set("depth", 0.04);
        bufReader->set("rate", 0.01);
        bufReader->set("fdbk", 0.08);
        bufReader-> set("decay", 0.01);
    }
    else if (key=='x') {
        bufReader->set("delay", ofRandom(0.1));
        bufReader->set("depth", ofRandom(0.1));
        bufReader->set("rate", ofRandom(0.03));
        bufReader->set("fdbk", ofRandom(0.2));
        bufReader->set("decay", ofRandom(0.03));
    }

}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){
    
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){
    
}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){
    
}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){
    
}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){
    
}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){
    
}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){
    
}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){
    
}
