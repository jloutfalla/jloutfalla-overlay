# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/yaul-org/libyaul.git"
	inherit git-r3
	KEYWORDS="-* ~amd64"
else	
	SRC_URI="https://github.com/yaul-org/libyaul/archive/refs/tags/${PV}.tar.gz"
	S="${WORKDIR}/lib${P}"

	KEYWORDS="amd64"
fi

inherit edo

DESCRIPTION="An open source SEGA Saturn development kit"
HOMEPAGE="https://www.yaul.org"

LICENSE="MIT"
SLOT="0"

DEPEND="dev-games/yaul-toolchain dev-libs/libisoburn"
RDEPEND="${DEPEND}"
BDEPEND=""

RESTRICT="strip"

_INSTALL_RELPATH="opt/yaul-toolchain/sh2eb-elf"
YAUL_PREFIX="${ED}/${_INSTALL_RELPATH}"

_change_env_value() {
	local _variable="${1}"
	local _value="${2}"
	local _out="${3}"

	awk -F '=' '/^export '"${_variable}"'=.+/ { print $1 "='"${_value}"'"; getline; } { print; }' "${_out}" > "${_out}.tmp" || die "Awk failed"
	mv "${_out}.tmp" "${_out}"
}

src_prepare() {
	eapply "${FILESDIR}/${PN}-bcl-ld.patch"
	eapply_user

	mkdir -p "${_TMP_INSTALL}"

	edo _change_env_value "YAUL_INSTALL_ROOT" "/${_INSTALL_RELPATH}" "${S}/yaul.env.in"
	edo _change_env_value "YAUL_BUILD_ROOT" "\$HOME" "${S}/yaul.env.in"
	edo _change_env_value "YAUL_BUILD" "build" "${S}/yaul.env.in"

	cp yaul.env.in "${S}/yaul.env.build" || die "Failed to copy env file"
	edo _change_env_value "YAUL_BUILD_ROOT" "${S}" "${S}/yaul.env.build"
	edo _change_env_value "SILENT" "" "${S}/yaul.env.build"

	cp -v "${S}/yaul.env.build" "${S}/yaul.env.package"
	edo _change_env_value "YAUL_INSTALL_ROOT" "${ED}/${_INSTALL_RELPATH}" "${S}/yaul.env.package"
}

src_compile() {
	(
		source yaul.env.build || die "Can not source build environment file"
		emake release tools
	)
}

src_install() {
	dodir "${_INSTALL_RELPATH}"
	(
		source yaul.env.package || die "Can not source package environment file"
		emake install-release install-tools
	)

	insinto "${_INSTALL_RELPATH}"
	newins "${S}/yaul.env.in" yaul.env.in
}

pkg_postinst() {
	elog "Please be sure to copy,"
	elog "	/${_INSTALL_RELPATH}/yaul.env.in"
	elog "to"
	elog "	\$HOME/.yaul.env"
	elog "and source it."
}

