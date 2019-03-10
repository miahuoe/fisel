#include "edit.h"
#include <stdio.h>

void edit_init(edit *E, char *buf, size_t bufs)
{
	E->cur_x = E->cur_y = 0;
	E->bufs = bufs;
	E->begin = E->cur = E->end = buf;
	memset(E->begin, 0, E->bufs);
}

static void update_cursor_pos(edit *E)
{
	int b, cp, w = 0;
	char *B;

	B = E->begin;
	while (B != E->cur && (b = utf8_dechar(&cp, B))) {
		w += utf8_width(cp);
		B += b;
	}
	E->cur_x = w;
	E->cur_y = 0;
}

void edit_move(edit *E, int n)
{
	int b, cp;
	if (n > 0) {
		while (n-- && E->cur != E->end && (b = utf8_dechar(&cp, E->cur))) {
			E->cur += b;
		}
	}
	else if (n < 0) {
		while (n++ && E->cur != E->begin) {
			while (!(b = utf8_b2len(E->cur))) {
				E->cur--;
			}
			E->cur--;
		}
	}
	update_cursor_pos(E);
}

void edit_insert(edit *E, char *s, size_t sl)
{
	char *src, *dst;
	int i;

	if ((E->end-E->begin)+sl >= E->bufs) {
		return;
	}

	src = E->end-1;
	dst = E->end+sl-1;
	for (i = 0; i < E->end-E->cur; i++) {
		*dst = *src;
		dst--;
		src--;
	}
	memcpy(E->cur, s, sl);
	E->cur += sl;
	E->end += sl;
	update_cursor_pos(E);
}

void edit_delete(edit *E, int n)
{
	char *A, *B;
	int b, cp;

	A = B = E->cur;
	if (n > 0) {
		while (n-- && B != E->end && (b = utf8_dechar(&cp, B))) {
			B += b;
		}
	}
	else if (n < 0) {
		while (n++ && A != E->begin) {
			while (!(b = utf8_b2len(A))) {
				A--;
			}
			A--;
		}
	}
	memmove(A, B, E->end-B);
	E->end -= B-A;
	E->cur = A;
	update_cursor_pos(E);
}