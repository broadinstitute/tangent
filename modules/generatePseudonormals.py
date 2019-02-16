#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Feb  9 19:46:21 2018

@author: galengao
"""
import sys
import multiprocessing
from itertools import chain
import numpy as np
import pandas as pd

from sklearn.decomposition import TruncatedSVD

def get_tumor_list(sif_file):
    # df = pd.read_table(sif_file, index_col=0)
    df = pd.read_csv(sif_file, sep='\t', index_col=0)
    return list(df[df['TUMOR_NORMAL']=='Tumor'].index)

def load_input(cov_file, seg_file, tumors):
    # Parse pre-tangent coverage file
    # df_c = pd.read_table(cov_file, usecols=['Chr','Start','Stop']+tumors, low_memory=False)
    df_c = pd.read_csv(cov_file, sep='\t', usecols=['Chr','Start','Stop']+tumors, low_memory=False)
    df_c.index = df_c.Chr.apply(lambda x: str(x))+':'+df_c.Start.apply(lambda x: str(x))+'-'+df_c.Stop.apply(lambda x: str(x))
    df_c['Chr'] = df_c.Chr.replace({'X':23, 'Y':24}).apply(lambda x: int(x))
        
    # Parse post-tangent segment table file
    #df_s = pd.read_table(seg_file)
    df_s = pd.read_csv(seg_file, sep='\t')
    df_s.columns = ['samp','Chr','Start','Stop','n','log2cn']
    df_s.samp = df_s.samp.str.replace('.', '-')
    df_s = df_s[df_s.samp.isin(tumors)].replace({'X':23, 'Y':24})
    df_s.Chr = [int(x) for x in df_s.Chr]
    df_s = df_s.sort_values(by=['samp','Chr','Start'])

    return df_c, df_s

def perform_signal_decomposition(df_c, tumors, n=50):
    '''Perform signal decomposition of samples using tSVD.'''
    tsvd = TruncatedSVD(n_components=n, n_iter=20, random_state=42)
    X = tsvd.fit_transform(df_c[tumors].T.as_matrix())
    print('tSVD Explained Var.: %.5f' % sum(tsvd.explained_variance_ratio_))
    df_out = df_c[['Chr','Start','Stop']]
    df_out = df_out.join(pd.DataFrame(np.matmul(X, tsvd.components_), \
                                      index=tumors, columns=df_c.index).T)
    return df_out

def compute_log_cn(df_c, tumors):
    '''Compute median-normalized log2 copy number profiles for all tumors.'''
    t_medians = np.median(df_c[tumors], axis=0)
    df_out = df_c[['Chr','Start','Stop']]
    df_out[['log2cn_'+t for t in tumors]] = np.log2(df_c[tumors] / t_medians)
    return df_out, t_medians

#def old_pseudonormalize_tumor(t, df_c, df, med):
#    '''Perform pseudonormalization for a single tumor t with median med.'''
##    print(t, sum(df['n']), len(df_f))
#    print(t)
#    df_c[t+'-PN'] = np.nan
#    segchr = {c:df[df.Chr==c] for c in df.Chr.unique()}
#    for i, row in df_c.iterrows():
#        c, s = int(row['Chr']), row['Start']
#        df = segchr[c]
#        if len(df[(df.Start<=s)&(df.Stop>=s)]) == 1:
#            df_c.at[i, t+'-PN'] = df[(df.Start<=s)&(df.Stop>=s)]['log2cn']
#    
##        if sum(df['n']) == len(df_f):
##        smeans = [df.at[x,'log2cn'] for x in df.index for i in range(df.at[x,'n'])]
##        sub_cov = 2**(np.array(df_c['log2cn_'+t])-np.array(smeans))*med
#    sub_cov = 2**(np.array(df_c['log2cn_'+t])-df_c[t+'-PN'])*med
#    df0 = pd.DataFrame(sub_cov, index=df_c.index, columns=[t+'-PN'])
#    return df0

def pseudonormalize_tumor(t, df_cov, df, med):
    '''Perform pseudonormalization for a single tumor t with median med.'''
    print(t)
    segchr = {c:df[df.Chr==c] for c in df.Chr.unique()}
    segchr[24] = pd.DataFrame([t, 24, 2655028, 27770600, 0, np.nan], index=df.columns).T
    covchr = {c:df_cov[df_cov.Chr==c] for c in df_cov.Chr.unique()}

    smeans = []
    for c in df_cov.Chr.unique():
        df_c, df = covchr[c], segchr[c]
        abs_b, abs_e = df_c['Start'][0], df_c['Start'][-1]
        endpts = np.sort(list({abs_b, abs_e} | set(df.Start) | set(df.Stop)))
        cndict, ndict = {}, {} # dicts of log2cn & n indexed by segstart
        for i, s in enumerate(endpts[:-1]):
            if s in set(df.Start): # if there's a segment starting at that endpt
                cndict[s] = float(df[df.Start==s]['log2cn'])
            else:
                cndict[s] = np.nan
            ndict[s] = len(df_c[(df_c.Start>=s)&(df_c.Start<endpts[i+1])])
        ndict[endpts[-2]] = ndict[endpts[-2]]+1
        smeans += list(chain(*[[cndict[s]]*ndict[s] for s in endpts[:-1]]))
    
    sub_cov = 2**(np.array(df_cov['log2cn_'+t])-np.array(smeans))*med
    df0 = pd.DataFrame(sub_cov, index=df_cov.index, columns=[t+'-PN'])
    return df0


def subtract_seg(df_c, df_s, tumors):
    '''Subtract segmentation profiles from corresponding coverage profiles.'''
    df_p = df_c[['Chr','Start','Stop']]
    # transform coverage profile into log2 space to perform subtraction
    df_c, medians = compute_log_cn(df_c, tumors)
    # perform signal subtraction for each tumor
#    df_f = pd.read_table(filtmarkfile, usecols=['Marker'], index_col=0)
#    df_c = df_c[df_c.index.isin(df_f.index)]

    dfs, df_cs = [df_s[df_s.samp==t] for t in tumors], [df_c for t in tumors]
    parallel_inputs = zip(tumors, df_cs, dfs, medians)
    for pi in parallel_inputs:
        df0 = pseudonormalize_tumor(*pi)
        df_p = df_p.join(df0, how='left')

    return df_p.dropna(axis=0)

def generate_pseudonormal_matrix(df_c, df_s, tumors, n=0):
    '''Given matrix of log2 relative CN coverage, table of segs, and a list of
    tumors, generate and return formatted pseudonormal matrix.'''
    # perform segmentation subtraction
    df_p = subtract_seg(df_c, df_s, tumors)
    # Perform signal decomposition with tSVD
    if n_svd >= 1:
        print('Performing SVD limiting to %d eigenvectors...' % n)
        df_p = perform_signal_decomposition(df_p, df_p.columns[3:], n=n_svd)
    return df_p.replace({23:'X', 24:'Y'})

def partition_dataset(df_doc_tn, df_doc_pn, tumors, n_files, outDir):
    '''Partition tumors into n equal sets while also creating their complement
    sets of pseudonormal samples'''
    ps,ts = list(df_doc_pn.columns[3:]),[x[:-3] for x in df_doc_pn.columns[3:]]
    df_pn_sif = pd.DataFrame([ps,['Normal' for x in ps]], \
                             index=['Array','TUMOR_NORMAL']).T.set_index('Array')
    df_t_sif = pd.DataFrame([ts,['Tumor' for x in ts]], \
                            index=['Array','TUMOR_NORMAL']).T.set_index('Array')
    order = []
    for i in range(n_files):
        # partition and write out sif files
        df_x = df_t_sif.iloc[i::n_files]
        df_xc = df_pn_sif[~df_pn_sif.index.isin([x+'-PN' for x in df_x.index])]
        df_x.to_csv(outDir+'/sif_files/tumors_'+str(i)+'.sif.txt', sep='\t')
        df_xc.to_csv(outDir+'/sif_files/tumors_'+str(i)+'c.sif.txt', sep='\t')
        # partition and write out doc files
        df_y = df_doc_tn[['Chr','Start','Stop'] + list(df_x.index)]
        df_yc = df_doc_pn[['Chr','Start','Stop'] + list(df_xc.index)]
        df_y.to_csv(outDir+'/doc_files/tumors_'+str(i)+'.D.txt', sep='\t', index=False)
        df_yc.to_csv(outDir+'/doc_files/tumors_'+str(i)+'c.D.txt', sep='\t', index=False)
        # save file paths
        order.append([outDir+'/sif_files/tumors_'+str(i)+'c.sif.txt', \
                      outDir+'/doc_files/tumors_'+str(i)+'c.D.txt', \
                      outDir+'/sif_files/tumors_'+str(i)+'.sif.txt', \
                      outDir+'/doc_files/tumors_'+str(i)+'.D.txt'])
    # save orders as a file containing paths to direct workflow later
    pd.DataFrame(order).to_csv(outDir+'/pseudonormal_runs_parameters.txt', \
                sep='\t', index=False, header=False)

if __name__ == '__main__':
    # parse command line inputs
    cov_file = sys.argv[1]
    seg_file = sys.argv[2]
    filtmarkfile = sys.argv[3]
    sif_file = sys.argv[4]
    outDir = sys.argv[5]
    n_files = int(sys.argv[6]) # integer between 1 and total number of tumors
    n_svd = int(sys.argv[7]) # integer from 1 to total # tums; use 0 for no svd

    # Load list of tumors. Then get their raw coverage and segment profiles.
    tumors = get_tumor_list(sif_file)
    df_c, df_s = load_input(cov_file, seg_file, tumors)

#    # Perform Signal Subtraction
    df_p = generate_pseudonormal_matrix(df_c, df_s, tumors, n=n_svd)
    print('Computed pseudonormal coverage profiles from tumor coverage file.')
    
#    # Partition results and write them to disk
    df_c = df_c[df_c.index.isin(df_p.index)]
    partition_dataset(df_c, df_p, tumors, n_files, outDir)
    print('Tumor SIF and DOC files partitioned into '+str(n_files)+' sets.')