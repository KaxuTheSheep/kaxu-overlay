# Copyright 2022-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit savedconfig toolchain-funcs

MY_PV="${PV/_rc/-rc}"
MY_P="${PN}-v${MY_PV}"

DESCRIPTION="dwm for Wayland"
HOMEPAGE="https://codeberg.org/dwl/dwl"
SRC_URI="https://codeberg.org/${PN}/${PN}/releases/download/v${MY_PV}/${MY_P}.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="CC0-1.0 GPL-3+ MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="X"

COMMON_DEPEND="
	dev-libs/libinput:=
	dev-libs/wayland
	gui-libs/wlroots:0.20=[libinput,session,X?]
	x11-libs/libxkbcommon
	X? (
		x11-libs/libxcb:=
		x11-libs/xcb-util-wm
	)
"
RDEPEND="
	${COMMON_DEPEND}
	X? (
		x11-base/xwayland
	)
"
# uses <linux/input-event-codes.h>
DEPEND="
	${COMMON_DEPEND}
	sys-kernel/linux-headers
"
# 0.9 adds ext-data-control, ext-image-copy-capture and friends;
# verify the exact minimum against upstream before relying on this
BDEPEND="
	>=dev-libs/wayland-protocols-1.39
	>=dev-util/wayland-scanner-1.23
	virtual/pkgconfig
"

src_prepare() {
	restore_config config.h

	# 0.8-era patches (movestack, bar) add keybindings whose functions
	# no longer exist in an unpatched 0.9
	if [[ -f config.h ]] && grep -qE 'movestack|togglebar' config.h; then
		die "The saved config.h contains patch-specific code (movestack/togglebar); remove it or regenerate from config.def.h"
	fi

	default
}

src_compile() {
	emake PKG_CONFIG="$(tc-getPKG_CONFIG)" CC="$(tc-getCC)" \
		XWAYLAND="$(usev X -DXWAYLAND)" XLIBS="$(usev X "xcb xcb-icccm")" dwl
}

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
	dodoc CHANGELOG.md README.md

	save_config config.h
}

pkg_postinst() {
	local v
	for v in ${REPLACING_VERSIONS}; do
		if ver_test "${v}" -lt 0.9; then
			elog "dwl 0.9 uses modifier-independent key symbols in config.h keybindings."
			elog "If you use savedconfig, compare your saved config.h with the new"
			elog "config.def.h before rebuilding."
			break
		fi
	done
}
