#!/bin/sh

source conf.sh

function setup() {
	
	git clone git@git.mobexs.com:flipper/ios-template-application.git	

	#copy required content to destination folder
    addModules
	copyTemplateResourses

	#parse project.yml and set config values
	setProjectName
    setBundleIDs
    setTargetName
    setDeploymentTarget	
    setupCodeSigning
    setConfigTeamID

	#generate xcode project using project.yml
	xcodegen

	#remove ios template project repository
	cleanTemporaryTemplateResourses

	#codesigning
	setupFastlaneFiles
	addCoding
	createAppID
	getProfiles
}

function addModules {

    #coredata
    cd ios-template-application
    if [ $USE_COREDATA == 'default' ]
    then
        echo "adding subtree coredata storage"
        git subtree add --prefix IOS-APP/Classes/Storage git@git.mobexs.com:flipper/coredata-storage.git master --squash;
        setDataBaseName

    else
        echo "No CoreData"
    fi
    cd ..
}

function setProjectName() {	
	sed -i '' "s|___PROJECT_NAME___|"$PROJECT_NAME"|g" project.yml
}

function setBundleIDs() {
	sed -i '' "s|___BUNDLE_ID_RELEASE___|"$BUNDLE_ID_PROD"|g" project.yml
    sed -i '' "s|___BUNDLE_ID_STAGING___|"$BUNDLE_ID_STAGING"|g" project.yml
}

function setTargetName() {
	sed -i '' "s|___PROD_TARGET_NAME___|"$PROD_TARGET_NAME"|g" project.yml
}

function setDeploymentTarget() {
	sed -i '' "s|___DEPLOYMENT_TARGET___|"$DEPLOYMENT_TARGET"|g" project.yml
}

function setConfigTeamID() {
	sed -i '' "s|___DEVELOPMENT_TEAM_ID___|"$DEVELOPMENT_TEAM_ID"|g" Configs/config.xcconfig
}

function copyTemplateResourses() {
	cp -a ./ios-template-application/Configs ./
	cp -a ./ios-template-application/IOS-APP ./
	cp -a ./ios-template-application/IOS-APP_UITests ./
	cp -a ./ios-template-application/IOS-APP_UnitTests ./
	cp -a ./ios-template-application/IOS-APP_UnitTests ./
	cp -a ./ios-template-application/README ./
	cp -a ./ios-template-application/scripts ./	
	cp -a ./ios-template-application/project.yml ./	
	cp -a ./ios-template-application/fastlane ./
    cp -a ./ios-template-application/Gemfile ./
    cp -a ./ios-template-application/Gemfile.lock ./
}

function cleanTemporaryTemplateResourses() {
	rm -rf ios-template-application
	rm -rf project.yml
}

#modules 
function setDataBaseName() {
	
	find . -iname '___DATABASE_NAME___.xcdatamodel' -execdir mv -i '{}' "$PROD_TARGET_NAME".xcdatamodel \;
	sed -i '' "s|___DATABASE_NAME___|"$PROD_TARGET_NAME"|g" IOS-APP/Classes/Storage/Storage.swift
}

#codesigning
function setupFastlaneFiles() {
	
	## AppFile	
	#1. parse and replace bundleIDs
	sed -i '' "s|___BUNDLE_ID_RELEASE___|"$BUNDLE_ID_PROD"|g" fastlane/Appfile
    sed -i '' "s|___BUNDLE_ID_STAGING___|"$BUNDLE_ID_STAGING"|g" fastlane/Appfile
    sed -i '' "s|___BUNDLE_ID_RELEASE___|"$BUNDLE_ID_PROD"|g" fastlane/Fastfile
    sed -i '' "s|___BUNDLE_ID_STAGING___|"$BUNDLE_ID_STAGING"|g" fastlane/Fastfile

    #2. parse and replace Dev Team ID
    sed -i '' "s|___DEVELOPMENT_TEAM_ID___|"$DEVELOPMENT_TEAM_ID"|g" fastlane/Appfile

    #3. parse and replace fastlane git storage with certificates and profiles
    sed -i '' "s|___FASTLANE_CREDENTIALS_URL___|"$FASTLANE_CREDENTIALS_URL"|g" fastlane/Matchfile

    #5.  parse and replace itunes conenct team ID
    sed -i '' "s|___ITUNES_CONNECT_TEAM_ID___|"$ITUNES_CONNECT_TEAM_ID"|g" fastlane/Appfile
}

function addCoding {

	echo "setup UTF-8 symbols"
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
}

function createAppID() {
	#create app id for prod target application
	fastlane produce -u "$DEVPORTAL_LOGIN" -q "$PROJECT_NAME" -a "$BUNDLE_ID_PROD" --skip_itc

	#create app id for prod staging application
	fastlane produce -u "$DEVPORTAL_LOGIN" -q "$PROJECT_NAME""-test" -a "$BUNDLE_ID_STAGING" --skip_itc
}

function getProfiles() {

    #fastlane match development
	fastlane match appstore
	fastlane match adhoc
}

setup
