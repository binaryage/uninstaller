# Notes to older myself

This is just the core of the app. You must also create uninstaller-resources on parent level and point it to your (customized) resources. TotalFinder resources are located [here](https://github.com/binaryage/totalfinder-i18n/tree/master/uninstaller).

    git clone git@github.com:binaryage/uninstaller.git
    ln -s path/to/resources uninstaller-resources
    cd uninstaller
    xcodebuild