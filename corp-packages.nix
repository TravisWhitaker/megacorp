pkgs:
let licenseHack = p :
    pkgs.runCommand "licenseHack"
    {
        buildInputs = [];
    } ''
        mkdir $out
        cp -Lr ${p}/* $out/
        rm -f $out/LICENSE
        touch $out/LICENSE
    '';
    notCross = p : p.buildPlatform == p.targetPlatform;
in
{
    foreign-lib-standalone-hello =
    {
        name = "foreign-lib-standalone-hello";
        src = builtins.fetchGit
        {
            url = "https://github.com/TravisWhitaker/foreign-lib-standalone-hello";
            ref = "master";
            rev = "31a04e9fa4b7837bbdfcb65ba067c4dfc7828a0e";
        };
        supportedPlatform = _ : true;
        planOverride = _ : {};
    };

    haskell-build-acid =
    {
        name = "haskell-build-acid";
        src = builtins.fetchGit
        {
            url = "https://github.com/TravisWhitaker/haskell-build-acid";
            ref = "master";
            rev = "d6bf9e56daf7df46673126f244035db947d8696d";
        };
        supportedPlatform = _ : true;
        planOverride = _ : {};
    };

    vector-fftw =
    {
        name = "vector-fftw";
        src = builtins.fetchGit
        {
            url = "https://github.com/bgamari/vector-fftw";
            ref = "master";
            rev = "61ff19daae86ffdad06a886769cf61ee99d25937";
        };
        supportedPlatform = _ : true;
        planOverride = _ : {};
    };

    vulkan-examples =
    {
        name = "vulkan-examples";
        src = "${(builtins.fetchGit
        {
            url = "https://github.com/expipiplus1/vulkan";
            ref = "master";
            rev = "b59f1b3c1e00e1b49b76c844df5c662b4b8ed2d2";
        })}/examples";
        supportedPlatform = _ : true;
        planOverride = pkgs:
        {
        };
    };
}
