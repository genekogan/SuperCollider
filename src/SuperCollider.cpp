#include "SuperCollider.h"


SuperColliderSynthParameter::SuperColliderSynthParameter(ofxSCSynth *synth, string name, float value, float min, float max)
{
    this->synth = synth;
    parameter.set(name, value, min, max);
    parameter.addListener(this, &SuperColliderSynthParameter::parameterChanged);
}

void SuperColliderSynthParameter::parameterChanged(float & v)
{
    synth->set(parameter.getName(), parameter);
}

SuperColliderSynth::SuperColliderSynth(string name, ofxSCGroup *group)
{
    this->group = group;
    synth = new ofxSCSynth(name);
}

void SuperColliderSynth::set(string arg, double value)
{
    synth->set(arg, value);
}

void SuperColliderSynth::create()
{
    if (group == NULL) {
        synth->create();
    }
    else {
        synth->addToTail(*group);
    }
}

void SuperColliderSynth::addToHead()
{
    if (group == NULL) {
        synth->addToHead();
    }
    else {
        synth->addToHead(*group);
    }
}

void SuperColliderSynth::addToTail()
{
    if (group == NULL) {
        synth->addToTail();
    }
    else {
        synth->addToTail(*group);
    }
}

string SuperColliderSynth::getInfo()
{
    string s = getName() + "\n============\n";
    map<string,SuperColliderSynthParameter*>::iterator it = parameters.begin();
    for (; it != parameters.end(); ++it) {
        s += " -> " + it->second->getParameter().getName() + " {"+ofToString(it->second->getParameter().getMin())+", "+ofToString(it->second->getParameter().getMax())+"}\n";
    }
    return s;
}

SuperColliderSynth::~SuperColliderSynth()
{
    free();
}

ofParameter<float> & SuperColliderSynth::addParameter(string name, float value, float min, float max)
{
    SuperColliderSynthParameter *newParameter = new SuperColliderSynthParameter(synth, name, value, min, max);
    if (parameters.count(name) > 0) {
        delete parameters[name];
    }
    parameters[name] = newParameter;
    return newParameter->getParameter();
}

void SuperColliderSynth::addBuffer(string name)
{
    buffers.push_back(name);
}

void SuperColliderSynth::addControlBus(string name)
{
    controlBusses.push_back(name);
}

void SuperColliderSynth::addAudioBus(string name)
{
    audioBusses.push_back(name);
}

ofxSCGroup * SuperCollider::addGroup(string name)
{
    ofxSCGroup *group = new ofxSCGroup();
    if (groups.size() == 0) {
        group->create();
    }
    else {
        group->addToTail(*groups[groups.size()-1]);
    }
    groups.push_back(group);
    return group;
}

SuperColliderSynth * SuperCollider::addSynth(string name, ofxSCGroup *group)
{
    SuperColliderSynth *newSynth = new SuperColliderSynth(name, group);
    if (synths.count(name) > 0) {
        name += "("+ofToString(synths.count(name))+")";
    }
    synths[name] = newSynth;
    return newSynth;
}

ofxSCBuffer * SuperCollider::addBuffer(string name, int frames, int channels)
{
    ofxSCBuffer *buffer = new ofxSCBuffer(frames, channels);
    if (buffers.count(name) > 0) {
        buffers[name]->free();
        delete buffers[name];
    }
    buffers[name] = buffer;
    return buffer;
}

ofxSCBus * SuperCollider::addControlBus(string name, int channels)
{
    ofxSCBus *bus = new ofxSCBus(RATE_CONTROL, channels);
    if (bussesK.count(name) > 0) {
        bussesK[name]->free();
        delete bussesK[name];
    }
    bussesK[name] = bus;
    return bus;
}

ofxSCBus * SuperCollider::addAudioBus(string name, int channels)
{
    ofxSCBus *bus = new ofxSCBus(RATE_AUDIO, channels);
    if (bussesA.count(name) > 0) {
        bussesA[name]->free();
        delete bussesA[name];
    }
    bussesA[name] = bus;
    return bus;
}


SuperCollider::~SuperCollider()
{
    map<string,SuperColliderSynth*>::iterator it = synths.begin();
    while (it != synths.end()) {
        delete it->second;
        synths.erase(it);
    }
}

void SuperCollider::draw()
{
    string s = "Synths\n\n";
    map<string,SuperColliderSynth*>::iterator it = synths.begin();
    for (; it != synths.end(); ++it) {
        s += it->second->getInfo() + "\n";
    }
    ofDrawBitmapString(s, 50, 50);
}

void SuperCollider::readFromFile(string synthType, string synthFile, ofxSCGroup *group) {
    ofFile file;
    file.open(synthFile);
    string sc3file = file.readToBuffer().getText();
    string exp = ofToString("\n@synthDef "+synthType+"\n(.+\n)+.+/\n");
  
    Poco::RegularExpression regEx("\n@synthDef "+synthType+"\n(.+\n)+.+/\n");
    Poco::RegularExpression::Match match;

    SuperColliderSynth *newSynth;
    while (regEx.match(sc3file, match) != 0)
    {
        string synthDef = sc3file.substr(match.offset, match.length);
        vector<string> statements = ofSplitString(synthDef, "\n");
        for (int j=0; j<statements.size(); j++) {
            vector <string> statement = ofSplitString(statements[j], " ");
            if (statement[0] == "@name") {
                newSynth = addSynth(statement[1], group);
            }
            else if (statement[0] == "@param") {
                float initialValue = statement.size() > 4 ? ofToFloat(statement[4]) : 0.5 * (ofToFloat(statement[2]), ofToFloat(statement[3]));
                newSynth->addParameter(statement[1], initialValue, ofToFloat(statement[2]), ofToFloat(statement[3]));
            }
            else if (statement[0] == "@controlBus") {
                newSynth->addControlBus(statement[1]);
            }
            else if (statement[0] == "@audioBus") {
                newSynth->addAudioBus(statement[1]);
            }
            else if (statement[0] == "@buffer") {
                newSynth->addBuffer(statement[1]);
            }
        }
        sc3file = sc3file.substr(match.offset + match.length);
    }
}
