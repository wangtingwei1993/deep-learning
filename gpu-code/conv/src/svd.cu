
//#include "svd.hpp"
using namespace std;

template <typename Dtype>
SVD<Dtype>::SVD(Matrix<Dtype> *A, const int m, const int n) \
        : _A(A), _height(m), _width(n), _alpha(0), \
        _sigma_u(0), _beta(0), _sigma_v(0), _scale_one(1), \
        _scale_minus_one(-1), _scale_zero(0){

    _householder_mat_p = new Matrix<Dtype>(n, n);
    _householder_mat_q = new Matrix<Dtype>(m, m);

    _householder_vec_u = new Matrix<Dtype>(m, 1);
    _householder_vec_v = new Matrix<Dtype>(n, 1);

    _w = new Matrix<Dtype>(m, 1);
    _z = new Matrix<Dtype>(n, 1);
    _x = new Matrix<Dtype>(n, 1);

    _k = new Matrix<Dtype>(m, 1);
    _l = new Matrix<Dtype>(n, 1);

    _h = new Matrix<Dtype>(m, m);
    _g = new Matrix<Dtype>(n, n);

    _cropped_A_for_u_v = new Matrix<Dtype>(m, 1);
    _cropped_A_for_z_w = new Matrix<Dtype>(m, n);

    cublasCreate(&handle);
}

template <typename Dtype>
SVD<Dtype>::~SVD(){
    delete _householder_mat_p;
    delete _householder_mat_q;

    delete _householder_vec_u;
    delete _householder_vec_v;

    delete _w;
    delete _z;
    delete _x;
    delete _k;
    delete _l;
    delete _h;
    delete _g;

    delete _cropped_A_for_u_v;
    delete _cropped_A_for_z_w;
//    cublasDestory(&handle);
}

template <typename Dtype>
void SVD<Dtype>::computeHouseHolderVecU(const int vec_start_idx){
    const int vec_u_len = _height - vec_start_idx;

    _A->cropMatToNew(_cropped_A_for_u_v, vec_start_idx, vec_u_len, \
          vec_start_idx, 1);

    computeHouseHolderVecAndAlpha(vec_u_len, \
         _householder_vec_u, _alpha, _sigma_u);

    cout << vec_u_len << ":" << _alpha << ":" << _sigma_u << endl;
//    _cropped_A_for_u_v->showValue("cropped_a");
    _householder_vec_u->showValue("u");

}

template <typename Dtype>
void SVD<Dtype>::computeHouseHolderVecV(const int vec_start_idx){
    const int vec_v_len = _width - vec_start_idx - 1;
    if (vec_v_len <= 0) {
        return;
    }
    _A->cropMatToNew(_cropped_A_for_u_v, vec_start_idx, 1, \
          vec_start_idx+1, vec_v_len);
    computeHouseHolderVecAndAlpha(vec_v_len, \
         _householder_vec_v, _beta, _sigma_v);
}

template <typename Dtype>
void SVD<Dtype>::computeHouseHolderVecAndAlpha(const int vec_len, \
		Matrix<Dtype> *householder_vector_gpu, Dtype &alpha_cpu, \
        Dtype &sigma_gpu){
    Dtype u_norm = _cropped_A_for_u_v->computeNorm(vec_len);
    Dtype y1_u = _cropped_A_for_u_v->getFirstPosValue();

//    cout << y1_u << ":"<< u_norm << endl;
    alpha_cpu = y1_u > 0 ? -u_norm : u_norm;
    sigma_gpu = (y1_u - alpha_cpu) / (-alpha_cpu);
    kComputeHouseholderVec<<<1, 1024>>>(_cropped_A_for_u_v->getDevData(), \
            householder_vector_gpu->getDevData(), \
			-alpha_cpu, 1/(y1_u - alpha_cpu), vec_len);
}

template <typename Dtype>
void SVD<Dtype>::computeH(const int vec_len) {
    cublasDgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, vec_len, vec_len,
                1, &_scale_one, _householder_vec_u->getDevData(), vec_len, \
		        _householder_vec_u->getDevData(), 1, &_scale_zero, \
                _h->getDevData(), vec_len);

    // Hi = I - sigma_u * u * u'
    _h->subedByUnitMat();
}

template <typename Dtype>
void SVD<Dtype>::eliminateA() {

}

