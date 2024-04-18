{lib, stdenv, fetchurl, makeWrapper, gnused, coreutils, psutils, gnugrep, hl3170cdwlpr }:

stdenv.mkDerivation rec {
  pname = "${model}cupswrapper";
  version = "1.1.4-0";

  model = "hl3170cdw";
  lprpkg = hl3170cdwlpr;
  fileNo = "006743";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf${fileNo}/${model}_cupswrapper_GPL_source_${version}.tar.gz";
    hash = "sha256-E3GSwiMRkuiCIJYkDozoYUPfOqvopPqPPQt1uaMDEAU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  prePatch = ''
    substituteInPlace brcupsconfig/brcups_commands.h \
      --replace-fail "brprintconf[30]=\"" "brprintconf[130]=\"${lprpkg}/usr/bin/"

    substituteInPlace brcupsconfig/brcupsconfig.c \
      --replace-fail "exec[300]" "exec[400]"
  '';

  makeFlags = [ "-C brcupsconfig" ];

  installPhase = ''
    runHook preInstall

    lpr=${lprpkg}/opt/brother/Printers/${model}
    dir=$out/opt/brother/Printers/${model}

    # Extract the true brother_lpdwrapper_MODEL filter embedded in cupswrapperMODEL by
    # slicing out the relevant parts for the writing the embedded file, then running that.
    sed -n -e '/tmp_filter=/c\tmp_filter=lpdwrapper'  -e ' 1,/device_model=/p ; /<<!ENDOFWFILTER/,/!ENDOFWFILTER/p ; ' \
      cupswrapper/cupswrapper${model} > lpdwrapperbuilder
    sh lpdwrapperbuilder
    chmod +x lpdwrapper
    mkdir -p $out/lib/cups/filter
    cp lpdwrapper $out/lib/cups/filter/brother_lpdwrapper_${model}

    mkdir -p $out/share/cups/model/Brother
    cp PPD/brother_${model}_printer_en.ppd $out/share/cups/model/Brother/brother_${model}_printer_en.ppd

    mkdir -p $dir/cupswrapper/
    cp brcupsconfig/brcupsconfpt1 $dir/cupswrapper/

    runHook postInstall
  '';

  preFixup = ''
    substituteInPlace $out/lib/cups/filter/brother_lpdwrapper_${model} \
      --replace-fail /opt/brother/Printers/${model}/lpd "$lpr/lpd" \
      --replace-fail /opt/brother/Printers/${model}/inf "$lpr/inf" \
      --replace-fail /opt/brother/Printers/${model}/cupswrapper "$dir/cupswrapper" \
      --replace-fail /usr/bin/psnup "${psutils}/bin/psnup" \
      --replace-fail /usr/share/cups/model/Brother "$out/share/cups/model/Brother"

    wrapProgram $out/lib/cups/filter/brother_lpdwrapper_${model} \
      --prefix PATH ":" ${ lib.makeBinPath [ coreutils psutils gnused gnugrep ] }
  '';

  meta = with lib; {
    homepage = "http://www.brother.com/";
    description = "Brother ${model} CUPS driver";
    sourceProvenance = with sourceTypes; [ fromSource ];
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=${model}_all&os=128";
    maintainers = with maintainers; [ luna_1024 ];
  };
}
