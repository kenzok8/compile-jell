#!/bin/bash

shopt -s extglob
rm -rf feeds/jell/{diy,mt-drivers,shortcut-fe,luci-app-mtwifi,base-files}

for ipk in $(find feeds/jell/* -maxdepth 0 -type d);
do
	[[ "$(grep "KernelPackage" "$ipk/Makefile")" && ! "$(grep "BuildPackage" "$ipk/Makefile")" ]] && rm -rf $ipk || true
done

rm -rf feeds/jell/{luci-base,luci-mod-network,luci-mod-status,luci-mod-system}

#<<'COMMENT'
rm -Rf feeds/luci/{applications,collections,protocols,themes,libs,docs,contrib}
rm -Rf feeds/luci/modules/!(luci-base)
rm -Rf feeds/packages/!(lang|libs|devel|utils|net|multimedia)
rm -Rf feeds/packages/multimedia/!(gstreamer1|ffmpeg)
rm -Rf feeds/packages/libs/libcups
rm -Rf feeds/packages/net/!(mosquitto|curl)
rm -Rf feeds/base/package/{firmware}
rm -Rf feeds/base/package/network/!(services|utils)
rm -Rf feeds/base/package/network/services/!(ppp)
rm -Rf feeds/base/package/system/!(opkg|ubus|uci|ca-certificates)
rm -Rf feeds/base/package/kernel/!(cryptodev-linux)
#COMMENT

./scripts/feeds update -a
./scripts/feeds install -a -p jell -f
./scripts/feeds install -a

rm -rf feeds/packages/lang/golang
svn export https://github.com/coolsnowwolf/packages/trunk/lang/golang feeds/packages/lang/golang

sed -i 's/\(page\|e\)\?.acl_depends.*\?}//' `find package/feeds/jell/luci-*/luasrc/controller/* -name "*.lua"`
# sed -i 's/\/cgi-bin\/\(luci\|cgi-\)/\/\1/g' `find package/feeds/jell/luci-*/ -name "*.lua" -or -name "*.htm*" -or -name "*.js"` &
sed -i 's/Os/O2/g' include/target.mk

sed -i \
	-e "s/+\(luci\|luci-ssl\|uhttpd\)\( \|$\)/\2/" \
	-e "s/+nginx\( \|$\)/+nginx-ssl\1/" \
	-e 's/+python\( \|$\)/+python3/' \
	-e 's?../../lang?$(TOPDIR)/feeds/packages/lang?' \
	-e 's,$(STAGING_DIR_HOST)/bin/upx,upx,' \
	package/feeds/jell/*/Makefile

cp -f devices/common/.config .config
mv feeds/base feeds/base.bak
mv feeds/packages feeds/packages.bak
make defconfig
rm -Rf tmp
mv feeds/base.bak feeds/base
mv feeds/packages.bak feeds/packages
sed -i 's/CONFIG_ALL=y/CONFIG_ALL=n/' .config
sed -i '/PACKAGE_kmod-/d' .config

sed -i "/mediaurlbase/d" package/feeds/*/luci-theme*/root/etc/uci-defaults/*

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl

if [ -f /usr/bin/python ]; then
	ln -sf /usr/bin/python staging_dir/host/bin/python
else
	ln -sf /usr/bin/python3 staging_dir/host/bin/python
fi
ln -sf /usr/bin/python3 staging_dir/host/bin/python3
cp -f devices/common/po2lmo staging_dir/host/bin/po2lmo
chmod +x staging_dir/host/bin/po2lmo
