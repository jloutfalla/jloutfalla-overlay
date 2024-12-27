# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/yaul-org/libyaul-build-scripts.git"
	EGIT_SUBMODULES=( crosstool-ng )
	inherit git-r3
else
	SRC_URI="http://github.com/yaul-org/libyaul-build-scripts"
fi

inherit edo out-of-source-utils

DESCRIPTION="Toolchain for Yaul"
HOMEPAGE="https://www.yaul.org"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND="
	app-arch/unzip
	>=app-shells/bash-3.1
	sys-apps/help2man
	>=sys-apps/sed-4.0
	sys-apps/gawk
	sys-apps/texinfo
	sys-apps/which
	sys-devel/bison
	sys-devel/flex
	sys-apps/dtc
	app-arch/lzip
	net-misc/wget
"

RESTRICT="network-sandbox strip"

_TMP_TARBALLS="${T}/tarballs"
_INSTALL_RELPATH="${T}/opt/yaul-toolchain"

BUILD_DIR="${S}/crosstool-ng"


QA_WX_LOAD="opt/yaul-toolchain/sh2eb-elf/lib/gcc/sh2eb-elf/13.2.0/.*"
QA_PRESTRIPPED="
	${QA_WX_LOAD}
	opt/yaul-toolchain/sh2eb-elf/bin/.*
	opt/yaul-toolchain/sh2eb-elf/sh2eb-elf/bin/.*
	opt/yaul-toolchain/sh2eb-elf/libexec/gcc/sh2eb-elf/13.2.0/.*
"

src_prepare() {
	default

	rm -f .config

	cp configs/sh2eb-elf/native-linux.config .config
	edo sed -E -e 's#^(CT_DEBUG_CT)=.*#\1=n#g' \
	-e 's#^(CT_DEBUG_INTERACTIVE)=.*#\1=n#g' \
	-e 's#^(CT_STRIP_HOST_TOOLCHAIN_EXECUTABLES)=.*#\1=n#g' \
	-e 's#^(CT_STRIP_TARGET_TOOLCHAIN_EXECUTABLES)=.*#\1=n#g' \
	-e 's#^(CT_PREFIX_DIR)=.*$#\1="${CT_PREFIX:-'"${_INSTALL_RELPATH}"'}/${CT_HOST:+HOST-${CT_HOST}/}${CT_TARGET}"#g' \
	-e 's#^(CT_LOG_TO_FILE)=.*#\1=n#g' \
	-e 's#^(CT_LOG_FILE_COMPRESS)=.*#\1=n#g' \
	-i .config || die "Sed failed"

#	-e 's#^(CT_LOCAL_TARBALLS_DIR)=.*#\1='${_TMP_TARBALLS}'#g' \
#mkdir -p "${_TMP_TARBALLS}"
#chown -R portage:portage "${_TMP_TARBALLS}"

	mkdir -p "${_INSTALL_RELPATH}"

	run_in_build_dir ./bootstrap
}

src_configure() {
	run_in_build_dir econf --enable-local
}

src_compile() {
	run_in_build_dir emake

	local TMP_CFLAGS="${CFLAGS}" TMP_CXXFLAGS="${CXXFLAGS}"
	local ABI=64

	unset CFLAGS CXXFLAGS
	./crosstool-ng/ct-ng build || die "Failed to build toolchain"

	CFLAGS="${TMP_CFLAGS}"
	CXXFLAGS="${TMP_CXXFLAGS}"
}

src_install() {
	cp -R "${T}/opt" "${ED}" || die "Failed to copy toolchains to install directory"

	insinto /etc/profile.d
	newins "${FILESDIR}/yaul.sh" yaul.sh
}

