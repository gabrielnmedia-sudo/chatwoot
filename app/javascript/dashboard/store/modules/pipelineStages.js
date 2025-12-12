import * as types from '../mutation-types';
import PipelineStagesAPI from '../../api/pipelineStages';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getPipelineStages($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isFetching: true });
    try {
      const response = await PipelineStagesAPI.get();
      commit(types.default.SET_PIPELINE_STAGES, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, pipelineStage) => {
    commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isCreating: true });
    try {
      const response = await PipelineStagesAPI.create({
        pipeline_stage: pipelineStage,
      });
      commit(types.default.ADD_PIPELINE_STAGE, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message || error.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...pipelineStage }) => {
    commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: true });
    try {
      const response = await PipelineStagesAPI.update(id, {
        pipeline_stage: pipelineStage,
      });
      commit(types.default.EDIT_PIPELINE_STAGE, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message || error.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isDeleting: true });
    try {
      await PipelineStagesAPI.delete(id);
      commit(types.default.DELETE_PIPELINE_STAGE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.default.SET_PIPELINE_STAGES_UI_FLAG, { isDeleting: false });
    }
  },
  reorder: async ({ commit }, ordering) => {
    try {
      await PipelineStagesAPI.reorder(ordering);
      commit(types.default.SET_PIPELINE_STAGES_ORDER, ordering);
    } catch (error) {
      const errorMessage = error?.response?.data?.message || error.message;
      throw new Error(errorMessage);
    }
  },
};

export const mutations = {
  [types.default.SET_PIPELINE_STAGES_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_PIPELINE_STAGES]: ($state, data) => {
    $state.records = data;
  },
  [types.default.ADD_PIPELINE_STAGE]: ($state, data) => {
    $state.records.push(data);
  },
  [types.default.EDIT_PIPELINE_STAGE]: ($state, data) => {
    const index = $state.records.findIndex(
      pipelineStage => pipelineStage.id === data.id
    );
    $state.records.splice(index, 1, data);
  },
  [types.default.DELETE_PIPELINE_STAGE]: ($state, id) => {
    const index = $state.records.findIndex(
      pipelineStage => pipelineStage.id === id
    );
    $state.records.splice(index, 1);
  },
  [types.default.SET_PIPELINE_STAGES_ORDER]: ($state, ordering) => {
    $state.records.sort((a, b) => {
      return ordering.indexOf(a.id) - ordering.indexOf(b.id);
    });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
