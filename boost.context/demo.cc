#include <iostream>
#include <queue>
#include <string>

#include "fcontext.hpp"

using namespace std;

char sp1[8192];
char sp2[8192];

const char *textm = "main";
const char *text1 = "co1";
const char *text2 = "co2";

std::queue<transfer_t> co_queue;

transfer_t schedule(const char *data) {
	if (!co_queue.empty()) {
	  auto to = co_queue.front();
  	co_queue.pop();
	  auto wakeup_from = jump_fcontext(to.fctx, (void*)data);
  	co_queue.push(wakeup_from);
		return wakeup_from;
	}
	return transfer_t{};
}

string text(transfer_t t) {
	if (t.data)
		return string((const char*)t.data);
	else
		return "none";
}

void f0(transfer_t trans) {
}

void f1(transfer_t trans) {
	cout << "[F1]: entry " << text(trans) << endl;
	co_queue.push(trans);
	for(int i=0; i<3; i++) {
    cout << "[F1]: " << i << "\n";
		auto from = schedule(text1);
		cout << "[F1] wakeup from " << text(from) << endl;
	}
	schedule(text1);
}

void f2(transfer_t trans) {
	cout << "[F2] entry " << text(trans) << endl;
	co_queue.push(trans);
	for(int i=0; i<3; i++) {
    cout << "[F2]: " << i << "\n";
		auto from = schedule(text2);
		cout << "[F2] wakeup from " << text(from) << endl;
	}
	schedule(text2);
}

int main()
{
  transfer_t trans1,trans2;
  trans1.fctx = make_fcontext((char*)sp1+sizeof(sp1), sizeof(sp1), f1);
  trans1.data = (char*)text1;
  trans2.fctx = make_fcontext((char*)sp2+sizeof(sp2), sizeof(sp2), f2);
  trans2.data = (char*)text2;

	co_queue.push(trans1);
	co_queue.push(trans2);

	while(!co_queue.empty()) {
		auto from = schedule(textm);
		cout << "[MAIN] wakeup from " << text(from) << endl;
	}
	cout << "[MAIN] exit" << endl;
}
