{lib, stdenv, fetchurl, dpkg, makeWrapper, ghostscript, gnused, file, a2ps, coreutils, gawk, which, pkgsi686Linux }:

stdenv.mkDerivation rec {
  pname = "${model}lpr";
  version = "1.1.2-1";

  model = "hl3170cdw";
  fileNo = "007056";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf${fileNo}/${model}lpr-${version}.i386.deb";
    hash = "sha256-N1GjQHth5k4qhbfWLInzub9DcNsee4gKc3EW2WIfrko=";
  };

  nativeBuildInputs = [ makeWrapper dpkg ];

  unpackPhase = ''
    runHook preUnpack

    dpkg-deb -x $src $out

    runHook postUnpack
  '';

  dontBuild = true;

  preFixup = ''
    dir=$out/opt/brother/Printers/${model}
    interpreter=${pkgsi686Linux.glibc.out}/lib/ld-linux.so.2

    substituteInPlace $dir/lpd/filter${model} \
      --replace-fail /opt "$out/opt"
    substituteInPlace $dir/inf/setupPrintcapij \
      --replace-fail /opt "$out/opt" \
      --replace-fail printcap.local printcap

    wrapProgram $dir/lpd/filter${model} \
      --prefix PATH ":" ${ lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }

    wrapProgram $dir/inf/setupPrintcapij \
      --prefix PATH ":" ${ lib.makeBinPath [ coreutils gnused ] }

    wrapProgram $dir/lpd/psconvertij2 \
      --prefix PATH ":" ${ lib.makeBinPath [ ghostscript gnused coreutils gawk which ] }

    patchelf --set-interpreter "$interpreter" $dir/lpd/br${model}filter
    patchelf --set-interpreter "$interpreter" $out/usr/bin/brprintconf_${model}

    wrapProgram $dir/lpd/br${model}filter \
      --set LD_PRELOAD "${pkgsi686Linux.libredirect}/lib/libredirect.so" \
      --set NIX_REDIRECTS "/opt=$out/opt"

    wrapProgram $out/usr/bin/brprintconf_${model} \
      --set LD_PRELOAD "${pkgsi686Linux.libredirect}/lib/libredirect.so" \
      --set NIX_REDIRECTS "/opt=$out/opt"
  '';

  meta = with lib; {
    homepage = "http://www.brother.com/";
    description = "Brother ${model} LPR driver";
    sourceProvenance = with sourceTypes; [ binaryNativeCode fromSource ];
    license = with licenses; [ unfree gpl2Plus ];
    platforms = [ "x86_64-linux" "i686-linux" ];
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=${model}_all&os=128";
    maintainers = with maintainers; [ luna_1024 ];
  };
}
