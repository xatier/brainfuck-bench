//http://stackoverflow.com/questions/6853548/optimisation-for-a-brainfuck-interpreter
#include <cstdio>
#include <vector>

#define PROGRAM '+', '+', '+', '+', '+', '+', '+', '+', '[', '-', '>',  \
        '-', '[', '-', '>', '-', '[', '-', '>', '-', '[', '-', ']', '<', \
        ']', '<', ']', '<', ']', '>', '+', '+', '+', '+', '+', '+', '+', \
        '+', '[', '<', '+', '+', '+', '+', '+', '+', '+', '+', '+', '+', \
        '>', '-', ']', '<', '[', '>', '+', '>', '+', '<', '<', '-', ']', \
        '>', '-', '.', '>', '-', '-', '-', '-', '-', '.', '>'

template<char... all>
struct C;

template<char... rest>
struct C<'>', rest...> {
    typedef C<rest...> rest_t;
    typedef typename rest_t::remainder remainder;
    static char *body(char *p) {
        return rest_t::body(p+1);
    }
};

template<char... rest>
struct C<'<', rest...> {
    typedef C<rest...> rest_t;
    typedef typename rest_t::remainder remainder;
    static char *body(char *p) {
        return rest_t::body(p-1);
    }
};

template<char... rest>
struct C<'+', rest...> {
    typedef C<rest...> rest_t;
    typedef typename rest_t::remainder remainder;
    static char *body(char *p) {
        ++*p;
        return rest_t::body(p);
    }
};


template<char... rest>
struct C<'-', rest...> {
    typedef C<rest...> rest_t;
    typedef typename rest_t::remainder remainder;
    static char *body(char *p) {
        --*p;
        return rest_t::body(p);
    }
};

template<char... rest>
struct C<'.', rest...> {
    typedef C<rest...> rest_t;
    typedef typename rest_t::remainder remainder;
    static char *body(char *p) {
        putchar(*p);
        return rest_t::body(p);
    }
};

template<char... rest>
struct C<',', rest...> {
    typedef C<rest...> rest_t;
    typedef typename rest_t::remainder remainder;
    static char *body(char *p) {
        *p = getchar();
        return rest_t::body(p);
    }
};

template<char... rest>
struct C<'[', rest...> {
    typedef C<rest...> rest_t;
    typedef typename rest_t::remainder::remainder remainder;
    static char *body(char *p) {
        while (*p) {
            p = rest_t::body(p);
        }
        return rest_t::remainder::body(p);
    }
};


template<char... rest>
struct C<']', rest...> {
    typedef C<rest...> rest_t;
    struct remainder_hack {
        typedef typename rest_t::remainder remainder;
        static char *body(char *p) {
            return rest_t::body(p);
        }
    };
    typedef remainder_hack remainder;
    static char *body(char *p) {
        return p;
    }
};

template<>
struct C<> {
    static char *body(char *p) {
        return p;
    }
    struct remainder {
        static char *body(char *p) {
            return p;
        }
    };
};

int
main(int argc, char *argv[])
{
    std::vector<char> v(30000, 0);
    C<PROGRAM> thing;

    thing.body(&v[0]);
    return 0;
}
