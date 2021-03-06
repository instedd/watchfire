# Welcome to Watchfire

Watchfire is a simple and yet powerful system that initiates and tracks the process of building a volunteer response team with people who are geographically close to each other through phone calls and text message.

## Setup

Configuration settings are stored under 'config/settings.yml'. A template of the settings file is provided in 'config/settings.yml.template'. Rename (or copy) this file to 'settings.yml' and fill with your configuration. Settings are:

*	max_distance: maximum distance to look for volunteers (in miles)
*	nuntium_host: host name for Nuntium (usually https://nuntium.instedd.org)
*	nuntium_account: name of your Nuntium account
*	nuntium_app: name of your Nuntium application
*	nuntium_app_passwd: password of your Nuntium application
*	verboice_host: host name for Verboice (usually https://verboice.instedd.org)
*	verboice_account: email of your Verboice account
*	verboice_password: password of your Verboice account
*	verboice_channel: name of your Verboice channel
*	available_ratio: ratio (0 to 1) of available people. This is a probabilistic measure of people attending an event. For example if this is set to 0.5 and the required volunteers for an event is 10, then the system will start calling 20 people.
*	ispeech_api_key: ispeech.org API key (leave blank if you don't want to use ispeech)
