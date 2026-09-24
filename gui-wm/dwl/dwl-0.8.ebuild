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
IUSE="X autostart bar movestack"

COMMON_DEPEND="
	dev-libs/libinput:=
	dev-libs/wayland
	gui-libs/wlroots:0.19=[libinput,session,X?]
	x11-libs/libxkbcommon
	X? (
		x11-libs/libxcb:=
		x11-libs/xcb-util-wm
	)
	bar? (
		media-libs/fcft
		x11-libs/pixman
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
BDEPEND="
	>=dev-libs/wayland-protocols-1.32
	>=dev-util/wayland-scanner-1.23
	virtual/pkgconfig
"

src_prepare() {
	restore_config config.h

	# Patches add code to config.def.h, which a saved config.h would hide.
	# Fail early with a clear message rather than with a compiler error.
	if [[ -f config.h ]]; then
		local flag sym
		for flag in autostart bar movestack; do
			case ${flag} in
				bar) sym=togglebar ;;
				*)   sym=${flag} ;;
			esac
			if use "${flag}"; then
				grep -q "${sym}" config.h || die \
					"USE=${flag} is enabled but the saved config.h has no '${sym}'; merge it in from the patched config.def.h"
			elif grep -q "${sym}" config.h; then
				die "The saved config.h references '${sym}' but USE=${flag} is disabled"
			fi
		done
	fi

	PATCHES=()
	use autostart && PATCHES+=( "${FILESDIR}/autostart-${PV}.patch" )
	use bar       && PATCHES+=( "${FILESDIR}/bar-${PV}.patch" )
	use movestack && PATCHES+=( "${FILESDIR}/movestack-${PV}.patch" )

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
