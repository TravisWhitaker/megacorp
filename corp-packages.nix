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
}
