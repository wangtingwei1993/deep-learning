///
/// \file data.hpp
///
#ifndef DATA_HPP_
#define DATA_HPP_

#include <iostream>
#include <vector>
#include <stdio.h>

template <typename Dtype>
class Data {

public:
	Data() {}
	virtual ~Data() {}

	void copyFromHost(Dtype* data_value, const int data_len);
	void copyFromDevice(Data<Dtype>* dev_data);
	void copyToHost(Dtype* data_value, const int data_len);
	void copyToDevice(Data<Dtype>* dev_data);

	void zeros();

	inline Dtype* getDevData() const {
		return _data_value;
	}


protected:
	//数据形状不固定，由子类来定
	std::vector<int> _shape;
	Dtype* _data_value;
	bool _is_own_data;
	int _amount;
};

#include "../src/data.cu"

#endif
