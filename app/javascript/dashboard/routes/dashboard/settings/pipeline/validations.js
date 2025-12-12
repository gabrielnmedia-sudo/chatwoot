import { required, minLength } from '@vuelidate/validators';

export const validStageCharacters = (str = '') => !!str && !str.includes(' ');

export const getStageTitleErrorMessage = validation => {
  let errorMessage = '';
  if (!validation.name.$error) {
    errorMessage = '';
  } else if (!validation.name.required) {
    errorMessage = 'PIPELINE_MGMT.FORM.NAME.REQUIRED_ERROR';
  } else if (!validation.name.minLength) {
    errorMessage = 'PIPELINE_MGMT.FORM.NAME.MINIMUM_LENGTH_ERROR';
  } else if (!validation.name.validStageCharacters) {
    errorMessage = 'PIPELINE_MGMT.FORM.NAME.VALID_ERROR';
  }
  return errorMessage;
};

export default {
  name: {
    required,
    minLength: minLength(2),
  },
  color: {
    required,
  },
};
