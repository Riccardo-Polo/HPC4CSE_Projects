#ifndef DATA_H
#define DATA_H
#include <cassert>

// typedef for real type
typedef double real_t;

namespace data {
// define some helper types that can be used to pass simulation
// data around without haveing to pass individual parameters
struct Discretization {
    int nx;       // grid points in x and y dimension
    int nt;       // number of time steps
    int N;        // total number of grid points
    real_t dt;    // time step size
    real_t dx;    // distance between grid points
    real_t alpha; // dx^2/(D*dt)
    real_t beta;  // R*dx^2/D
};

extern Discretization options;

// thin wrapper around a pointer that can be accessed as either a 2D or 1D array
// Field has dimension xdim * ydim in 2D, or length=xdim*ydim in 1D
class Field {
    public:
    // default constructor
    Field() : ptr_(0), xdim_(0), ydim_(0) { }
    // constructor
    Field(int xdim, int ydim) : xdim_(xdim), ydim_(ydim) {
        #ifdef DEBUG
        assert(xdim>0 && ydim>0);
        #endif
        ptr_ = new real_t[xdim*ydim];
    }

    // destructor
    ~Field() { free(); }

    void init(int xdim, int ydim) {
        #ifdef DEBUG
        assert(xdim>0 && ydim>0);
        #endif
        free();
        ptr_ = new real_t[xdim*ydim];
        #ifdef DEBUG
        assert(xdim>0 && ydim>0);
        #endif
        xdim_ = xdim;
        ydim_ = ydim;
    }

    real_t*       data()       { return ptr_; }
    const real_t* data() const { return ptr_; }

    // access via (i,j) pair
    inline real_t&       operator() (int i, int j)        {
        #ifdef DEBUG
        assert(i>=0 && i<xdim_ && j>=0 && j<ydim_);
        #endif
        return ptr_[i+j*xdim_];
    }
    inline real_t const& operator() (int i, int j) const  {
        #ifdef DEBUG
        assert(i>=0 && i<xdim_ && j>=0 && j<ydim_);
        #endif
        return ptr_[i+j*xdim_];
    }

    // access as a 1D field
    inline real_t      & operator[] (int i) {
        #ifdef DEBUG
        assert(i>=0 && i<xdim_*ydim_);
        #endif
        return ptr_[i];
    }
    inline real_t const& operator[] (int i) const {
        #ifdef DEBUG
        assert(i>=0 && i<xdim_*ydim_);
        #endif
        return ptr_[i];
    }

    int xdim()   const { return xdim_; }
    int ydim()   const { return ydim_; }
    int length() const { return xdim_*ydim_; }

    private:

    void free() {
        if (ptr_) delete[] ptr_;
        ptr_ = 0;
    }

    real_t* ptr_;
    int xdim_;
    int ydim_;
};

// fields that hold the solution
extern Field y_new, y_old; // 2d
extern Field bndN, bndE, bndS, bndW; // 1d

}

#endif /* DATA_H */
