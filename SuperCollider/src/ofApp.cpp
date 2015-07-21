#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    ofSetWindowShape(1280, 800);
    
    synths = sc3.addGroup("synths");
    effects1 = sc3.addGroup("effects1");
    effects2 = sc3.addGroup("effects2");
    
    buffer = sc3.addBuffer("buffy3", 4 * 44100, 1);

    //buffer->read("/Users/gene/Audio/FieldRec/delaplane VA/fencewires_mono.wav");
    buffer->read("/Users/gene/Audio/FieldRec/germany/woodblocks_in_koblenz_mono.wav");
    
    minSigBus = sc3.addControlBus("min sig", 1);
    phaseBus = sc3.addControlBus("phase", 1);
    audioBus1 = sc3.addAudioBus("audioOut1", 1);
    audioBus2 = sc3.addAudioBus("audioOut2", 1);

    sc3.readFromFile("source", "/Users/gene/Code/of_v0.8-4.4_osx_release/of-tools/SuperCollider/synths.scd", synths);
    sc3.readFromFile("modifier", "/Users/gene/Code/of_v0.8-4.4_osx_release/of-tools/SuperCollider/synths.scd", effects1);
    sc3.readFromFile("modifier", "/Users/gene/Code/of_v0.8-4.4_osx_release/of-tools/SuperCollider/synths.scd", effects2);
    
    /*
    // buffer writer
    bufWriter = sc3.addSynth("bufWriter");
    bufWriter->set("channel", 0);
    
    bufWriter->addBuffer("bufnum");
    bufWriter->addControlBus("phasBus");
    bufWriter->addControlBus("minSigBus");
    
//    bufWriter->set("bufnum", buffer->index);
//    bufWriter->set("phasBus", phaseBus->index);
//    bufWriter->set("minSigBus", minSigBus->index);
    isManual.makeReferenceTo(bufWriter->addParameter("manual", 0, 0, 1));
    manualGate.makeReferenceTo(bufWriter->addParameter("manualGate", 0, 0, 1));
    
    bufReader = sc3.addSynth("bufReader");
//    bufReader->set("bufnum", buffer->index);
//    bufReader->set("phasBus", phaseBus->index);
    
    bufReader->addBuffer("bufnum");
    bufReader->addControlBus("phasBus");

    
    gain.makeReferenceTo(bufReader->addParameter("gain", 3, 0, 8));
    delayTime.makeReferenceTo(bufReader->addParameter("delayTime", 1, 0, 2));
    decayTime.makeReferenceTo(bufReader->addParameter("decayTime", 1, 0, 2));
    
    bufWriter->create();
    bufReader->create();
    
    
    minSigBus->set(0.1);
    
    decayTime = 1;
    delayTime = 1;
    gain = 1.2;
*/
    
    sc3.setupGui();
}

//--------------------------------------------------------------
void ofApp::update(){
    
    if (ofGetKeyPressed()) {
        //gain = ofMap(mouseX, 0, ofGetWidth(), 0, 8);
        //delayTime = ofMap(mouseX, 0, ofGetWidth(), 0, 2);
        //decayTime = ofMap(mouseY, 0, ofGetHeight(), 0, 2);
        minSigBus->set(ofMap(mouseX, 0, ofGetWidth(), 0, 0.5));
    }
    
    //bufReader->set("manualGate", manualGate);
}

//--------------------------------------------------------------
void ofApp::draw(){return;
    sc3.draw();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if (key=='1') {
        isManual = 1;
        manualGate = 1-manualGate;
        cout << "manual gate " << manualGate << " " << isManual << endl;
    }
    if (key=='2') {
        isManual = 0;
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
