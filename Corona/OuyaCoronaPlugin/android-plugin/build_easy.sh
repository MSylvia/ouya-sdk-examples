rm -r -f bin
rm -r -f gen
./build.plugin.sh ~/android/android-sdk-macosx/ /Applications/CoronaEnterprise/

echo cp bin/plugin.ouya.jar ../../InAppPurchasesPlugin/android/libs/
cp bin/plugin.ouya.jar ../../InAppPurchasesPlugin/android/libs/

echo cp bin/plugin.ouya.jar ../../VirtualControllerPlugin/android/libs/
cp bin/plugin.ouya.jar ../../VirtualControllerPlugin/android/libs/

echo cp bin/plugin.ouya.jar ../../Submission/ouya/plugins/2014.2428/android/
cp bin/plugin.ouya.jar ../../Submission/ouya/plugins/2014.2428/android/
